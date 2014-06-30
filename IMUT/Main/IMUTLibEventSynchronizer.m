#import "IMUTLibEventsLogPacket.h"
#import "IMUTLibLogPacketStreamWriter.h"
#import "IMUTLibConstants.h"
#import "IMUTLibEventSynchronizer.h"
#import "IMUTLibTimer.h"
#import "IMUTLibFunctions.h"
#import "IMUTLibSessionInitLogPacket.h"
#import "IMUTLibSyncLogPacket.h"
#import "IMUTLibMain+Internal.h"
#import "IMUTLibFinalLogPacket.h"
#import "IMUTLibUtil.h"

@interface IMUTLibEventSynchronizer ()

- (void)run;

- (void)clockDidStart:(NSNotification *)notification;

- (void)clockDidStop:(NSNotification *)notification;

@end

@implementation IMUTLibEventSynchronizer {
    IMUTLibDeltaEntityBag *_lastPersistedDeltaEntityBag;
    IMUTLibDeltaEntityBag *_currentDeltaEntityBag;

    NSTimeInterval _syncTimeInterval;
    IMUTLibTimer *_timer;

    dispatch_queue_t _dispatchQueue;
}

SINGLETON

- (instancetype)init {
    if (self = [super init]) {
        // Persisted event counter
        _eventCount = 0;

        // Delta entity bags
        _currentDeltaEntityBag = [IMUTLibDeltaEntityBag new];
        _lastPersistedDeltaEntityBag = [IMUTLibDeltaEntityBag new];

        // Timer
        _syncTimeInterval = 0.25;
        _dispatchQueue = makeDispatchQueue(@"synchronizer", DISPATCH_QUEUE_SERIAL, DISPATCH_QUEUE_PRIORITY_HIGH);
        _timer = repeatingTimer(_syncTimeInterval * 0.75, self, @selector(run), _dispatchQueue, NO);

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

- (IMUTLibDeltaEntity *)persistedEntityForKey:(NSString *)key {
    return [_lastPersistedDeltaEntityBag deltaEntityForKey:key];
}

- (void)enqueueDeltaEntity:(id)deltaEntity {
    @synchronized (_currentDeltaEntityBag) {
        [_currentDeltaEntityBag addDeltaEntity:deltaEntity];
    }
}

- (void)dequeueDeltaEntityWithKey:(NSString *)key {
    @synchronized (_currentDeltaEntityBag) {
        [_currentDeltaEntityBag removeDeltaEntityWithKey:key];
    }
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
- (void)logWriter:(IMUTLibLogPacketStreamWriter *)logWriter willWriteLogPackets:(NSArray **)packetQueue {
    if((*packetQueue).count <= 1) {
        return;
    }

    NSMutableArray *newPacketQueue = [NSMutableArray array];
    NSObject <IMUTLibLogPacket> *curLogPacket;
    IMUTLibEventsLogPacket *refEventsLogPacket, *curEventsLogPacket;
    NSTimeInterval referenceTime = 0.0;

    for (curLogPacket in *packetQueue) {
        if ([curLogPacket logPacketType] == IMUTLibLogPacketTypeEvents) {
            curEventsLogPacket = (IMUTLibEventsLogPacket *) curLogPacket;

            if(!refEventsLogPacket || referenceTime != [curEventsLogPacket relativeTime]) {
                if(refEventsLogPacket) {
                    [newPacketQueue addObject:refEventsLogPacket];
                    _eventCount += refEventsLogPacket.deltaEntityBag.count;
                }

                refEventsLogPacket = curEventsLogPacket;
                referenceTime = [curEventsLogPacket relativeTime];
                continue;
            } else {
                [refEventsLogPacket mergeIn:curEventsLogPacket];
                continue;
            }
        }

        if(refEventsLogPacket) {
            [newPacketQueue addObject:refEventsLogPacket];
            _eventCount += refEventsLogPacket.deltaEntityBag.count;
            refEventsLogPacket = nil;
        }

        [newPacketQueue addObject:curLogPacket];
    }

    if(refEventsLogPacket) {
        [newPacketQueue addObject:refEventsLogPacket];
        _eventCount += refEventsLogPacket.deltaEntityBag.count;
    }

    // Swap the packet queue
    *packetQueue = nil; // ARC?
    *packetQueue = newPacketQueue;
}

#pragma mark Private

- (void)clockDidStart:(NSNotification *)notification {
    dispatch_sync(_dispatchQueue, ^{
        _eventCount = 0;

        // Prepare new logwriter
        [_logWriter newFile];

        // Enqueue initial packets
        [_logWriter enqueuePacket:[IMUTLibSessionInitLogPacket new]];
        [_logWriter enqueuePacket:[IMUTLibSyncLogPacket new]];

        // Post notification
        [IMUTLibUtil postNotificationName:IMUTLibEventSynchronizerDidStartNotification
                                   object:self
                             onMainThread:NO
                            waitUntilDone:YES];

        // Treat already present entities as initial ones
        [self run];

        // Prepare and start timer
        //_timer.tolerance = (_syncTimeInterval >= 5.0) ? _syncTimeInterval * 0.1 : 0;
        [_timer resume];
    });
}

- (void)clockDidStop:(NSNotification *)notification {
    dispatch_sync(_dispatchQueue, ^{
        // Post notification
        [IMUTLibUtil postNotificationName:IMUTLibEventSynchronizerWillStopNotification
                                   object:self
                             onMainThread:NO
                            waitUntilDone:YES];

        // Write out all collected entities and reset timer
        [_timer fireAndPause];

        // Enqueue final log packet
        [_logWriter enqueuePacket:[IMUTLibFinalLogPacket new]];

        // Stop the log writer
        [_logWriter closeFileWaitUntilDone:YES];
    });
}

// Generate and write out a new events packet
- (void)run {
    if (_currentDeltaEntityBag.count) {
        IMUTLibDeltaEntityBag *enqueueableDeltaEntityBag;
        IMUTLibSession *session = [IMUTLibMain imut].session;

        @synchronized (_currentDeltaEntityBag) {
            enqueueableDeltaEntityBag = [_currentDeltaEntityBag copy];
            [_lastPersistedDeltaEntityBag mergeWithBag:_currentDeltaEntityBag];
            [_currentDeltaEntityBag reset];
        }

        NSTimeInterval timeInterval = [self alignTimeInterval:session.sessionDuration];
        id <IMUTLibLogPacket> logPacket = [IMUTLibEventsLogPacket packetWithDeltaEntityBag:enqueueableDeltaEntityBag
                                                                    timeIntervalSinceStart:timeInterval];

        if (timeInterval == 0) {
            [logPacket setAdditionalParameters:@{
                kIMUTLibInitialEventsPacket : numYES
            }];
        }

        [_logWriter enqueuePacket:logPacket];
    }
}

- (void)clearCache {
    @synchronized (_currentDeltaEntityBag) {
        [_currentDeltaEntityBag reset];
        [_lastPersistedDeltaEntityBag reset];
    }
}

@end
