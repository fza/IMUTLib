#import <libkern/OSAtomic.h>
#import "IMUTLibTimer.h"
#import "Macros.h"

#define LOCK_INVALID 1
#define LOCK_PAUSED 2
#define TEST_INVALID (LOCK_INVALID == OSAtomicAnd32OrigBarrier(LOCK_INVALID, &_flags))
#define TEST_PAUSED (LOCK_PAUSED == OSAtomicAnd32OrigBarrier(LOCK_PAUSED, &_flags))
#define LOCK(value) (0 == OSAtomicTestAndSetBarrier(8 - value, &_flags))
#define UNLOCK(value) (0 == OSAtomicTestAndClearBarrier(8 - value, &_flags))

@interface IMUTLibTimer ()

- (void)setupTimer;

- (void)teardownTimer;

- (void)resetTimerProperties;

- (void)timerFired;

- (void)callSelectorOnTarget;

@end

@implementation IMUTLibTimer {
    __weak id _target;
    SEL _selector;
    BOOL _repeats;

    dispatch_queue_t _privateSerialQueue;
    dispatch_source_t _timer;

    NSTimeInterval _timeInterval;
    NSTimeInterval _tolerance;

    OSSpinLock _callLock;

    uint32_t _flags; // Initialized to zero by runtime
    BOOL _scheduled;
}

@dynamic timeInterval;
@dynamic tolerance;
@dynamic scheduled;
@dynamic invalidated;

DESIGNATED_INIT

+ (instancetype)scheduleTimerWithTimeInterval:(NSTimeInterval)timeInterval target:(id)target selector:(SEL)selector repeats:(BOOL)repeats dispatchQueue:(dispatch_queue_t)dispatchQueue {
    IMUTLibTimer *timer = [[self alloc] initWithTimeInterval:timeInterval
                                                      target:target
                                                    selector:selector
                                                     repeats:repeats
                                               dispatchQueue:dispatchQueue];

    [timer schedule];

    return timer;
}

+ (instancetype)timerWithTimeInterval:(NSTimeInterval)timeInterval target:(id)target selector:(SEL)selector repeats:(BOOL)repeats dispatchQueue:(dispatch_queue_t)dispatchQueue {
    return [[self alloc] initWithTimeInterval:timeInterval
                                       target:target
                                     selector:selector
                                      repeats:repeats
                                dispatchQueue:dispatchQueue];
}

- (instancetype)initWithTimeInterval:(NSTimeInterval)timeInterval target:(id)target selector:(SEL)selector repeats:(BOOL)repeats dispatchQueue:(dispatch_queue_t)dispatchQueue {
    NSAssert(target && [target respondsToSelector:selector], @"Object does not respond to given selector.");
    NSAssert(dispatchQueue, @"Uninitialized dispatch queue given.");

    if (self = [super init]) {
        _target = target;
        _selector = selector;
        _repeats = repeats;

        _timeInterval = timeInterval;
        _tolerance = 0;

        _scheduled = NO;

        _callLock = OS_SPINLOCK_INIT;

        NSString *name = [NSString stringWithFormat:BUNDLE_IDENTIFIER_CONCAT("timer.%p"), (__bridge void *) self];
        _privateSerialQueue = dispatch_queue_create([name cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(_privateSerialQueue, dispatchQueue);
    }

    return self;
}

- (void)dealloc {
    [self invalidate];
}

- (NSTimeInterval)timeInterval {
    @synchronized (self) {
        return _timeInterval;
    }
}

- (void)setTimeInterval:(NSTimeInterval)timeInterval {
    @synchronized (self) {
        if (timeInterval != _timeInterval) {
            _timeInterval = timeInterval;

            if (_scheduled && !TEST_INVALID && !TEST_PAUSED) {
                [self resetTimerProperties];
            }
        }
    }
}

- (NSTimeInterval)tolerance {
    @synchronized (self) {
        return _tolerance;
    }
}

- (void)setTolerance:(NSTimeInterval)tolerance {
    @synchronized (self) {
        if (tolerance != _tolerance) {
            _tolerance = tolerance;

            if (_scheduled && !TEST_INVALID && !TEST_PAUSED) {
                [self resetTimerProperties];
            }
        }
    }
}

- (BOOL)scheduled {
    return _scheduled;
}

- (BOOL)paused {
    return TEST_PAUSED;
}

- (BOOL)invalidated {
    return TEST_INVALID;
}

- (BOOL)schedule {
    @synchronized (self) {
        if (!_scheduled && !TEST_INVALID) {
            _scheduled = YES;

            [self setupTimer];
        }
    }

    return _scheduled;
}

- (void)invalidate {
    if (LOCK(LOCK_INVALID)) {
        [self teardownTimer];
    }
}

- (BOOL)pause {
    @synchronized (self) {
        if (_scheduled && !TEST_INVALID && LOCK(LOCK_PAUSED)) {
            [self teardownTimer];

            return YES;
        }
    }

    return NO;
}

- (BOOL)resume {
    @synchronized (self) {
        if (!_scheduled) {
            return [self schedule];
        } else if (!TEST_INVALID && UNLOCK(LOCK_PAUSED) && dispatch_source_testcancel(_timer)) {
            [self setupTimer];

            return YES;
        }
    }

    return NO;
}

- (void)fireAndPause {
    if (!TEST_INVALID && !TEST_PAUSED) {
        [self pause];

        // If the timer is currently executing, we must wait
        OSSpinLockLock(&_callLock);
        [self callSelectorOnTarget];
        OSSpinLockUnlock(&_callLock);

        return;
    }
}

#pragma mark Private

- (void)setupTimer {
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _privateSerialQueue);

    [self resetTimerProperties];

    __weak IMUTLibTimer *weakSelf = self;
    dispatch_source_set_event_handler(_timer, ^{
        [weakSelf timerFired];
    });

    dispatch_resume(_timer);
}

- (void)teardownTimer {
    dispatch_source_cancel(_timer);
}

- (void)resetTimerProperties {
    uint64_t intervalInNanoseconds = (uint64_t) (_timeInterval * NSEC_PER_SEC);
    uint64_t toleranceInNanoseconds = (uint64_t) (_tolerance * NSEC_PER_SEC);

    dispatch_source_set_timer(_timer,
        dispatch_time(DISPATCH_TIME_NOW, intervalInNanoseconds),
        intervalInNanoseconds,
        toleranceInNanoseconds
    );
}

- (void)timerFired {
    // If we can't acquire the lock this means that the `fireAndPause`
    // method is running
    if(OSSpinLockTry(&_callLock)) {
        [self callSelectorOnTarget];

        if (!_repeats) {
            [self invalidate];
        }

        OSSpinLockUnlock(&_callLock);
    }
}

- (void)callSelectorOnTarget {
    if (TEST_INVALID) {
        return;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [_target performSelector:_selector withObject:self];
#pragma clang diagnostic pop
}

@end

IMUTLibTimer *repeatingTimer(NSTimeInterval timeInterval, id target, SEL selector, dispatch_queue_t dispatchQueue, BOOL schedule) {
    IMUTLibTimer *timer = [[IMUTLibTimer alloc] initWithTimeInterval:timeInterval
                                                              target:target
                                                            selector:selector
                                                             repeats:YES
                                                       dispatchQueue:dispatchQueue];

    if (schedule) {
        [timer schedule];
    }

    return timer;
}
