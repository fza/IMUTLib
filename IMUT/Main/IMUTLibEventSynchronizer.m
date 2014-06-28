#import "IMUTLibEventsLogPacket.h"
#import "IMUTLibLogPacketStreamWriter.h"
#import "IMUTLibConstants.h"
#import "IMUTLibEventSynchronizer.h"
#import "IMUTLibTimer.h"
#import "IMUTLibFunctions.h"
#import "IMUTLibSessionInitLogPacket.h"
#import "IMUTLibSyncLogPacket.h"
#import "IMUTLibMain+Internal.h"
#import "IMUTLibUtil.h"
#import "IMUTLibFinalizeLogPacket.h"

static dispatch_queue_t synchronizerQueue;

@interface IMUTLibEventSynchronizer ()

- (void)timerFired:(IMUTLibTimer *)timer;

- (void)clockDidStart:(NSNotification *)notification;

- (void)clockDidStop:(NSNotification *)notification;

- (void)resetCaches;

- (NSTimeInterval)alignTimeInterval:(NSTimeInterval)timeInterval;

@end

@implementation IMUTLibEventSynchronizer {
    IMUTLibDeltaEntityBag *_lastPersistedDeltaEntities;
    IMUTLibDeltaEntityBag *_currentDeltaEntities;
    IMUTLibLogPacketStreamWriter *_logWriter;
    IMUTLibTimer *_timer;
    BOOL _idle;
    BOOL _didEnqueueInitialPacket;
    NSTimeInterval _syncTimeInterval;
    NSDate *_syncReferenceDate;
    BOOL _firstStarted;
    unsigned long _eventCount;
}

SINGLETON

+ (void)initialize {
    synchronizerQueue = makeDispatchQueue(@"synchronizer", DISPATCH_QUEUE_SERIAL, DISPATCH_QUEUE_PRIORITY_HIGH);

    // Observe the clock
    [[NSNotificationCenter defaultCenter] addObserver:[self sharedInstance]
                                             selector:@selector(clockDidStart:)
                                                 name:IMUTLibClockDidStartNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:[self sharedInstance]
                                             selector:@selector(clockDidStop:)
                                                 name:IMUTLibClockDidStopNotification
                                               object:nil];
}

- (instancetype)init {
    if (self = [super init]) {
        // Initial state
        _idle = YES;
        _didEnqueueInitialPacket = NO;
        _timer = nil;
        _logWriter = nil;
        _firstStarted = NO;
        _currentDeltaEntities = [IMUTLibDeltaEntityBag new];
        _lastPersistedDeltaEntities = [IMUTLibDeltaEntityBag new];
        _syncTimeInterval = 0.25;
    }

    return self;
}

- (void)setSyncTimeInterval:(NSTimeInterval)syncTimeInterval {
    // Enforce range between 0.02s and 10.0s
    _syncTimeInterval = MIN(MAX(syncTimeInterval, 0.02), 10.0);

    if (_timer) {
        @synchronized (self) {
            if (_timer) {
                _timer.timeInterval = _syncTimeInterval;
            }
        }
    }
}

- (IMUTLibDeltaEntity *)persistedEntityForKey:(NSString *)key {
    return [_lastPersistedDeltaEntities deltaEntityForKey:key];
}

- (void)enqueueDeltaEntity:(id)deltaEntity {
    @synchronized (self) {
        [_currentDeltaEntities addDeltaEntity:deltaEntity];
    }
}

- (void)dequeueDeltaEntityWithKey:(NSString *)key {
    @synchronized (self) {
        [_currentDeltaEntities removeDeltaEntityWithKey:key];
    }
}

#pragma mark IMUTLibStreamLogWriterDelegate

// Consolidate log packets
// Because we align the reference time of each log packet, it can happen that
// some log packets will have the same reference time, thus _must_ be merged.
- (void)logWriter:(IMUTLibLogPacketStreamWriter *)logWriter willWriteLogPackets:(NSArray **)packetQueue {
    NSMutableArray *newPacketQueue = [NSMutableArray array];
    __block IMUTLibEventsLogPacket *refLogPacket, *curLogPacket;

    [*packetQueue enumerateObjectsUsingBlock:^(id <IMUTLibLogPacket> logPacket, NSUInteger index, BOOL *stop){
        if ([logPacket logPacketType] == IMUTLibLogPacketTypeEvents) {
            curLogPacket = (IMUTLibEventsLogPacket *) logPacket;
            if (!refLogPacket || [refLogPacket relativeTime] != [curLogPacket relativeTime]) {
                refLogPacket = curLogPacket;
            } else if (refLogPacket && [refLogPacket relativeTime] == [curLogPacket relativeTime]) {
                [refLogPacket.deltaEntityBag mergeWithCache:curLogPacket.deltaEntityBag];

                return;
            }
        }

        [newPacketQueue addObject:logPacket];
        _eventCount += curLogPacket.deltaEntityBag.count;
    }];

    // Swap the packet queue
    *packetQueue = newPacketQueue;
}

#pragma mark Private

- (void)clockDidStart:(NSNotification *)notification {
    if (!_idle) {
        return;
    }

    // The new sync reference date
    NSDate *syncReferenceDate = notification.userInfo[kStartDate];

    // Create new log writer
    IMUTLibLogPacketStreamWriter *logWriter = [IMUTLibLogPacketStreamWriter writerWithBasename:@"log"
                                                                                     sessionId:notification.userInfo[kSessionId]
                                                                             packetEncoderType:IMUTLibLogPacketEncoderJSON];

    logWriter.mayWrite = NO;

    // Enqueue first packets
    [logWriter enqueuePacket:[IMUTLibSessionInitLogPacket new]];
    [logWriter enqueuePacket:[IMUTLibSyncLogPacket packetWithSyncDate:syncReferenceDate
                                                        timeSourceInfo:[((id <IMUTLibTimeSource>) notification.userInfo[kTimeSource]) timeSourceInfo]]];

    // Create new timer
    IMUTLibTimer *timer = [[IMUTLibTimer alloc] initWithTimeInterval:_syncTimeInterval * 0.75 // run slighty faster than configured
                                                              target:self
                                                            selector:@selector(timerFired:)
                                                            userInfo:nil
                                                             repeats:YES
                                                       dispatchQueue:synchronizerQueue];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @synchronized (self) {
            if (!_idle) {
                return;
            }

            _idle = NO;
            _didEnqueueInitialPacket = NO;
            _timer = nil;
            _syncReferenceDate = syncReferenceDate;
            _eventCount = 0;
            _firstStarted = YES;

            _logWriter = logWriter;
            _logWriter.delegate = self;
            logWriter.mayWrite = YES;

            if (_firstStarted) {
                [self resetCaches];
            }

            [[NSNotificationCenter defaultCenter] postNotificationName:IMUTLibEventSynchronizerDidStartNotification
                                                                object:nil];

            _timer = timer;
            if (_syncTimeInterval >= 5.0) {
                _timer.tolerance = _syncTimeInterval * 0.1;
            }
            [_timer schedule];
        }
    });
}

- (void)clockDidStop:(NSNotification *)notification {
    if (!_idle) {
        @synchronized (self) {
            if (_idle) {
                return;
            }

            _idle = YES;
        }

        // Write out all collected entities and reset timer
        [_timer fire];
        [_timer invalidate];
        _timer = nil;

        NSTimeInterval sessionDuration = [self alignTimeInterval:[((NSNumber *) notification.userInfo[kSessionDuration]) doubleValue]];

        [_logWriter enqueuePacket:[IMUTLibFinalizeLogPacket packetWithSessionDuration:sessionDuration
                                                                           eventCount:_eventCount]];

        [_logWriter closeFileWaitUntilDone:YES];
        _logWriter = nil;
    }
}

- (void)timerFired:(IMUTLibTimer *)timer {
    // Generate and write out a new events packet
    if (_currentDeltaEntities.count > 0) {
        IMUTLibDeltaEntityBag *enqueueableDeltaEntityBag;
        BOOL asInitialPacket = NO;

        NSTimeInterval timeInterval = 0;
        if (_didEnqueueInitialPacket) {
            IMUTLibSession *session = [IMUTLibMain imut].session;
            if ([session timeSourceRunning]) {
                timeInterval = [self alignTimeInterval:[session.timeSource intervalSinceClockStart]];
            } else {
                return;
            }
        }

        @synchronized (self) {
            enqueueableDeltaEntityBag = [_currentDeltaEntities copy];

            if (!_didEnqueueInitialPacket) {
                _didEnqueueInitialPacket = YES;
                asInitialPacket = YES;
            }

            [_lastPersistedDeltaEntities mergeWithCache:_currentDeltaEntities];
            [_currentDeltaEntities reset];
        }

        id <IMUTLibLogPacket> logPacket = [IMUTLibEventsLogPacket packetWithDeltaEntityCache:enqueueableDeltaEntityBag
                                                                      timeIntervalSinceStart:timeInterval];

        if (asInitialPacket) {
            [logPacket setAdditionalParameters:@{
                kIMUTLibInitialEventsPacket : cYES
            }];
        }

        [_logWriter enqueuePacket:logPacket];
    }
}

- (void)resetCaches {
    [_currentDeltaEntities reset];
    [_lastPersistedDeltaEntities reset];
}

- (NSTimeInterval)alignTimeInterval:(NSTimeInterval)timeInterval {
    // Also tried ->
    // fabs(timeInterval / _syncTimeInterval) * _syncTimeInterval;
    // <- which results in a less precise value than the following:
    return timeInterval - fmod(timeInterval, _syncTimeInterval);
}

@end
