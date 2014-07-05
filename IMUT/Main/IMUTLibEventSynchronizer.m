#import "IMUTLibEventSynchronizer.h"
#import "IMUTLibPersistableEntityBag.h"
#import "IMUTLibTimer.h"
#import "IMUTLibFunctions.h"
#import "IMUTLibConstants.h"
#import "IMUTLibEventsLogPacket.h"
#import "IMUTLibSessionInitLogPacket.h"
#import "IMUTLibSyncLogPacket.h"
#import "IMUTLibUtil.h"
#import "IMUTLibFinalLogPacket.h"
#import "IMUTLibSession.h"
#import "IMUTLibMain+Internal.h"
#import "IMUTLibPollingModule.h"
#import "IMUTLibModuleRegistry.h"

@interface IMUTLibEventSynchronizer ()

- (void)run;

- (void)clockDidStart:(NSNotification *)notification;

- (void)clockDidStop:(NSNotification *)notification;

@end

@implementation IMUTLibEventSynchronizer {
    IMUTLibPersistableEntityBag *_lastPersistedEntityBag;
    IMUTLibPersistableEntityBag *_currentEntityBag;

    NSTimeInterval _syncTimeInterval;
    IMUTLibTimer *_timer;

    BOOL _didEnqueuInitialEvents;
    BOOL _isStopping;
}

SINGLETON

- (instancetype)init {
    if (self = [super init]) {
        // Persisted event counter
        _eventCount = 0;

        // Stop flag
        _isStopping = NO;

        // Initial events packet flag
        _didEnqueuInitialEvents = NO;

        // Delta entity bags
        _currentEntityBag = [IMUTLibPersistableEntityBag new];
        _lastPersistedEntityBag = [IMUTLibPersistableEntityBag new];

        // Cache last persistance time
        _lastPersistedEntityTime = 0;

        // Timing and dispatch
        _syncTimeInterval = 0.25;
        _dispatchQueue = makeDispatchQueue(@"synchronizer", DISPATCH_QUEUE_SERIAL, DISPATCH_QUEUE_PRIORITY_HIGH);
        _timer = makeRepeatingTimer(_syncTimeInterval * 0.75, self, @selector(run), _dispatchQueue, NO);

        // Log writer
        _logWriter = [IMUTLibLogPacketStreamWriter writerWithBasename:@"log"
                                                    packetEncoderType:IMUTLibLogPacketEncoderJSON];
        _logWriter.delegate = self;

        // Observe the clock
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter addObserver:self
                          selector:@selector(clockDidStart:)
                              name:IMUTLibClockDidStartNotification
                            object:nil];

        [defaultCenter addObserver:self
                          selector:@selector(clockDidStop:)
                              name:IMUTLibClockDidStopNotification
                            object:nil];
    }

    return self;
}

- (void)setSyncTimeInterval:(NSTimeInterval)syncTimeInterval {
    // Enforce range between 0.02s and 10.0s
    _syncTimeInterval = MIN(MAX(syncTimeInterval, 0.02), 10.0);
    _timer.timeInterval = _syncTimeInterval * 0.75;
}

- (IMUTLibPersistableEntity *)persistedEntityForKey:(NSString *)key {
    return [_lastPersistedEntityBag entityForKey:key];
}

- (void)enqueueEntity:(IMUTLibPersistableEntity *)entity {
    [_currentEntityBag addDeltaEntity:entity];
}

- (void)dequeueEntityWithKey:(NSString *)key {
    [_currentEntityBag removeDeltaEntityWithKey:key];
}

- (NSTimeInterval)alignTimeInterval:(NSTimeInterval)timeInterval {
    // Also tried ->
    // fabs(timeInterval / _syncTimeInterval) * _syncTimeInterval;
    // <- which results in a less precise value than the following:
    return timeInterval - fmod(timeInterval, _syncTimeInterval);
}

#pragma mark IMUTLibStreamLogWriterDelegate

// Consolidate log packets
// Because we align the reference time of each log packet, it can happen that
// some log packets will have the same reference time, thus _must_ be merged.
- (void)logWriter:(IMUTLibLogPacketStreamWriter *)logWriter willWriteLogPackets:(NSArray **)logPackets {
    if ((*logPackets).count <= 1) {
        return;
    }

    NSMutableArray *newPackets = [NSMutableArray array];
    IMUTLibLogPacket *curLogPacket;
    IMUTLibEventsLogPacket *refEventsLogPacket, *curEventsLogPacket;
    NSTimeInterval referenceTime = 0.0;

    for (curLogPacket in *logPackets) {
        if ([curLogPacket logPacketType] == IMUTLibLogPacketTypeEvents) {
            curEventsLogPacket = (IMUTLibEventsLogPacket *) curLogPacket;

            if (!refEventsLogPacket || referenceTime != [curEventsLogPacket relativeTime]) {
                if (refEventsLogPacket) {
                    [newPackets addObject:refEventsLogPacket];
                    _eventCount += refEventsLogPacket.entityBag.count;
                }

                refEventsLogPacket = curEventsLogPacket;
                referenceTime = [curEventsLogPacket relativeTime];
                continue;
            } else {
                [refEventsLogPacket mergeWith:curEventsLogPacket];
                continue;
            }
        }

        if (refEventsLogPacket) {
            [newPackets addObject:refEventsLogPacket];
            _eventCount += refEventsLogPacket.entityBag.count;
            refEventsLogPacket = nil;
        }

        [newPackets addObject:curLogPacket];
    }

    if (refEventsLogPacket) {
        [newPackets addObject:refEventsLogPacket];
        _eventCount += refEventsLogPacket.entityBag.count;
    }

    // Swap the packet queue
    *logPackets = nil; // ARC?
    *logPackets = newPackets;
}

#pragma mark Private

- (void)clockDidStart:(NSNotification *)notification {
    dispatch_sync(_dispatchQueue, ^{
        _eventCount = 0;
        _didEnqueuInitialEvents = NO;
        _isStopping = NO;

        // Prepare new logwriter
        [_logWriter createFile];

        // Enqueue initial packets
        [_logWriter enqueuePacket:[IMUTLibSessionInitLogPacket new]];
        [_logWriter enqueuePacket:[IMUTLibSyncLogPacket new]];

        // Post notification and wait until initial packets are available
        [IMUTLibUtil postNotificationName:IMUTLibEventSynchronizerDidStartNotification
                                   object:self
                             onMainThread:NO
                            waitUntilDone:YES];

        // Treat already present entities as initial ones
        [self run];

        // Prepare and start timer, a short leeway may be set when the sync time
        // interval is rather long
        _timer.tolerance = (_syncTimeInterval >= 5.0) ? _syncTimeInterval * 0.1 : 0;
        [_timer resume];
    });
}

- (void)clockDidStop:(NSNotification *)notification {
    dispatch_sync(_dispatchQueue, ^{
        _isStopping = YES;

        // Post notification
        [IMUTLibUtil postNotificationName:IMUTLibEventSynchronizerWillStopNotification
                                   object:self
                             onMainThread:NO
                            waitUntilDone:YES];

        // Write out all collected entities and reset timer
        [_timer pause];
        [self run];

        // Enqueue final log packet
        [_logWriter enqueuePacket:[IMUTLibFinalLogPacket new]];

        // Stop the log writer
        [_logWriter closeFile];

        _isStopping = NO;
    });
}

// Generate and write out a new events packet
- (void)run {
    if (_currentEntityBag.count) {
        IMUTLibPersistableEntityBag *enqueueableDeltaEntityBag;
        IMUTLibSession *session = [IMUTLibMain imut].session;

        enqueueableDeltaEntityBag = [_currentEntityBag copy];
        [_lastPersistedEntityBag mergeWithBag:_currentEntityBag];
        [_currentEntityBag reset];

        NSTimeInterval relativeTime;

        IMUTLibPersistableEntityMarking marking = 0;
        if (!_didEnqueuInitialEvents) {
            _didEnqueuInitialEvents = YES;
            relativeTime = 0; // Initial time is always 0
            marking = IMUTLibPersistableEntityMarkInitial;
        } else {
            if (_isStopping) {
                marking = IMUTLibPersistableEntityMarkFinal;
            }

            relativeTime = [self alignTimeInterval:session.duration];
        }

        if (marking) {
            for (IMUTLibPersistableEntity *entity in enqueueableDeltaEntityBag.all) {
                entity.entityMarking = marking;
            }
        }

        IMUTLibLogPacket *logPacket = [IMUTLibEventsLogPacket packetWithDeltaEntityBag:enqueueableDeltaEntityBag
                                                                               forTime:relativeTime];

        [_logWriter enqueuePacket:logPacket];

        _lastPersistedEntityTime = relativeTime;
    }

    for (IMUTLibPollingModule *module in [IMUTLibModuleRegistry sharedInstance].pollingModuleInstances) {
        [module poll];
    };
}

- (void)clearCache {
    [_currentEntityBag reset];
    [_lastPersistedEntityBag reset];
}

@end
