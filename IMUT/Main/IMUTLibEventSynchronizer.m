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

static dispatch_queue_t synchronizerQueue;

@interface IMUTLibEventSynchronizer ()

- (void)timerFired:(IMUTLibTimer *)timer;

- (void)clockDidStart;

- (void)clockDidStop;

- (void)resetCaches;

- (NSTimeInterval)alignTimeIntervalWithTimer:(NSTimeInterval)timeInterval;

@end

@implementation IMUTLibEventSynchronizer {
    IMUTLibDeltaEntityCache *_lastPersistedDeltaEntities;
    IMUTLibDeltaEntityCache *_currentDeltaEntities;
    IMUTLibLogPacketStreamWriter *_logWriter;
    IMUTLibTimer *_timer;
    BOOL _idle;
    BOOL _didEnqueueInitialPacket;
    NSTimeInterval _syncTimeInterval;
    NSDate *_syncReferenceDate;
    BOOL _firstStarted;
}

SINGLETON

+ (void)initialize {
    synchronizerQueue = makeDispatchQueue(@"synchronizer", DISPATCH_QUEUE_SERIAL, DISPATCH_QUEUE_PRIORITY_HIGH);

    // Observe the clock
    [[NSNotificationCenter defaultCenter] addObserver:[self sharedInstance]
                                             selector:@selector(clockDidStart)
                                                 name:IMUTLibClockDidStartNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:[self sharedInstance]
                                             selector:@selector(clockDidStop)
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

        // Initialize caches, so that modules may start producing events as soon as they
        // are created, though they shouldn't do that this early.
        [self resetCaches];

        self.syncTimeInterval = 0.25;
    }

    return self;
}

- (void)setSyncTimeInterval:(NSTimeInterval)syncTimeInterval {
    // Enforce range between 0.02s and 10.0s
    _syncTimeInterval = MIN(MAX(syncTimeInterval, 0.02), 10.0);
}

- (IMUTLibDeltaEntity *)persistedEntityForKey:(NSString *)key {
    @synchronized (self) {
        if (!_idle) {
            return [_lastPersistedDeltaEntities deltaEntityForKey:key];
        }
    }

    return nil;
}

- (void)enqueueDeltaEntity:(id)deltaEntity {
    @synchronized (self) {
        if (!_idle) {
            [_currentDeltaEntities addDeltaEntity:deltaEntity];
        };
    }
}

- (void)dequeueDeltaEntityWithKey:(NSString *)key {
    @synchronized (self) {
        if (!_idle) {
            [_currentDeltaEntities removeDeltaEntityWithKey:key];
        }
    }
}

#pragma mark IMUTLibStreamLogWriterDelegate

// Consolidate log packets
// Because we align the reference time of each log packet, it can happen that
// some log packets will have the same reference time, thus _must_ be merged.
- (void)logWriter:(IMUTLibLogPacketStreamWriter *)logWriter willWriteLogPackets:(NSArray **)packetQueue {
    NSMutableArray *newPacketQueue = [NSMutableArray array];
    __block IMUTLibEventsLogPacket *refLogPacket, *castedLogPacket;
    [*packetQueue enumerateObjectsUsingBlock:^(id <IMUTLibLogPacket> logPacket, NSUInteger idx, BOOL *stop){
        if ([logPacket logPacketType] == IMUTLibLogPacketTypeEvents) {
            castedLogPacket = (IMUTLibEventsLogPacket *) logPacket;
            if (!refLogPacket || [refLogPacket relativeTime] != [castedLogPacket relativeTime]) {
                refLogPacket = (IMUTLibEventsLogPacket *) logPacket;
            } else if (refLogPacket && [refLogPacket relativeTime] == [castedLogPacket relativeTime]) {
                [refLogPacket.deltaEntityCache mergeWithCache:castedLogPacket.deltaEntityCache];

                return;
            }
        }

        [newPacketQueue addObject:logPacket];
    }];

    // Swap the packet queue
    *packetQueue = newPacketQueue;
}

#pragma mark Private

- (void)clockDidStart {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @synchronized (self) {
            if (_idle) {
                // Set state
                _idle = NO;
                _didEnqueueInitialPacket = NO;
                _timer = nil;

                // Cache the start date of the clock
                IMUTLibSession *session = [IMUTLibMain imut].session;
                _syncReferenceDate = [session.timeSource startDate];

                // Create new log writer
                _logWriter = [IMUTLibLogPacketStreamWriter writerWithBasename:@"log"
                                                                    sessionId:session.sid
                                                            packetEncoderType:IMUTLibLogPacketEncoderJSON];

                // Let's inspect what is actually written
                _logWriter.delegate = self;

                // If the app is resuming, start with a fresh queue
                if (_firstStarted) {
                    [self resetCaches];
                }

                // Enqueue header packets
                [_logWriter enqueuePacket:[IMUTLibSessionInitLogPacket new]];
                [_logWriter enqueuePacket:[IMUTLibSyncLogPacket packetWithSyncDate:_syncReferenceDate
                                                                    timeSourceInfo:[session.timeSource timeSourceInfo]]];

                // Post notification that the synchronizer is about to start
                [IMUTLibUtil postNotificationOnMainThreadWithNotificationName:IMUTLibEventSynchronizerDidStartNotification
                                                                       object:nil
                                                                waitUntilDone:NO];

                // The actual timer that fires every sync time interval
                _timer = [[IMUTLibTimer alloc] initWithTimeInterval:_syncTimeInterval * 0.75 // fire slighty faster than configured
                                                             target:self
                                                           selector:@selector(timerFired:)
                                                           userInfo:nil
                                                            repeats:YES
                                                      dispatchQueue:synchronizerQueue];

                // Add some leeway if the interval is rather long
                if (_syncTimeInterval >= 5.0) {
                    _timer.tolerance = _syncTimeInterval * 0.1;
                }

                // Start the timer
                [_timer schedule];

                _firstStarted = YES;
            }
        }
    });
}

- (void)clockDidStop {
    @synchronized (self) {
        if (!_idle) {
            _idle = YES;

            // Write out all entities and reset the timer
            [_timer fire];
            [_timer invalidate];
            _timer = nil;

            // Close the log file and reset the log writer
            [_logWriter closeFile];
            _logWriter = nil;
        }
    }
}

- (void)timerFired:(IMUTLibTimer *)timer {
    // Generate and write out a new events packet
    @synchronized (self) {
        if (_currentDeltaEntities.count > 0) {
            NSTimeInterval timeInterval = 0;
            if (_didEnqueueInitialPacket) {
                IMUTLibSession * session = [IMUTLibMain imut].session;
                if ([session timeSourceRunning]) {
                    timeInterval = [self alignTimeIntervalWithTimer:[session.timeSource intervalSinceClockStart]];
                } else {
                    return;
                }
            }

            id <IMUTLibLogPacket> logPacket = [IMUTLibEventsLogPacket packetWithDeltaEntityCache:_currentDeltaEntities
                                                                          timeIntervalSinceStart:timeInterval];

            if (!_didEnqueueInitialPacket) {
                _didEnqueueInitialPacket = YES;

                [logPacket setAdditionalParameters:@{
                    kIMUTLibInitialEventsPacket : cYES
                }];
            }

            [_logWriter enqueuePacket:logPacket];

            [_lastPersistedDeltaEntities mergeWithCache:_currentDeltaEntities];

            // Create new entity cache for the next synchronization run
            _currentDeltaEntities = [IMUTLibDeltaEntityCache new];
        }
    }
}

- (void)resetCaches {
    _currentDeltaEntities = [IMUTLibDeltaEntityCache new];
    _lastPersistedDeltaEntities = [IMUTLibDeltaEntityCache new];
}

- (NSTimeInterval)alignTimeIntervalWithTimer:(NSTimeInterval)timeInterval {
    // Also tried ->
    // fabs(timeInterval / _syncTimeInterval) * _syncTimeInterval;
    // <- which in a less precise value than the following:
    return timeInterval - fmod(timeInterval, _syncTimeInterval);
}

@end
