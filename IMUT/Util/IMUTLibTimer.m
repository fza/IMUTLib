#import "IMUTLibTimer.h"
#import "Macros.h"
#import <libkern/OSAtomic.h>

@interface IMUTLibTimer ()

@property(nonatomic, weak) id target;
@property(nonatomic, assign) SEL selector;
@property(nonatomic, retain) id userInfo;
@property(nonatomic, assign) BOOL repeats;
@property(nonatomic, retain) dispatch_queue_t privateSerialQueue;
@property(nonatomic, retain) dispatch_source_t timer;

- (void)timerFired;

@end

// This class is heavily influenced by MSWeakTimer (c) MindSnacks
// @see https://github.com/mindsnacks/MSWeakTimer
@implementation IMUTLibTimer {
    struct {
        uint32_t timerIsInvalidated;
    } _timerFlags;
}

@synthesize timeInterval = _timeInterval;
@synthesize tolerance = _tolerance;

- (id)initWithTimeInterval:(NSTimeInterval)timeInterval
                    target:(id)target
                  selector:(SEL)selector
                  userInfo:(id)userInfo
                   repeats:(BOOL)repeats
             dispatchQueue:(dispatch_queue_t)dispatchQueue {
    NSParameterAssert(target);
    NSParameterAssert(selector);
    NSParameterAssert(dispatchQueue);

    if ((self = [super init])) {
        _timeInterval = timeInterval;
        self.target = target;
        self.selector = selector;
        self.userInfo = userInfo;
        self.repeats = repeats;

        NSString *privateQueueName = [NSString stringWithFormat:BUNDLE_IDENTIFIER_CONCAT("timer.%p"),
                                                                (__bridge void *) self];
        self.privateSerialQueue = dispatch_queue_create([privateQueueName cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(self.privateSerialQueue, dispatchQueue);
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.privateSerialQueue);
    }

    return self;
}

- (id)init {
    return [self initWithTimeInterval:0
                               target:nil
                             selector:NULL
                             userInfo:nil
                              repeats:NO
                        dispatchQueue:nil];
}

+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)timeInterval
                                        target:(id)target
                                      selector:(SEL)selector
                                      userInfo:(id)userInfo
                                       repeats:(BOOL)repeats
                                 dispatchQueue:(dispatch_queue_t)dispatchQueue {
    IMUTLibTimer *timer = [[self alloc] initWithTimeInterval:timeInterval
                                                      target:target
                                                    selector:selector
                                                    userInfo:userInfo
                                                     repeats:repeats
                                               dispatchQueue:dispatchQueue];

    [timer schedule];

    return timer;
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

            [self resetTimerProperties];
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

            [self resetTimerProperties];
        }
    }
}

- (void)resetTimerProperties {
    uint64_t intervalInNanoseconds = (uint64_t) (self.timeInterval * NSEC_PER_SEC);
    uint64_t toleranceInNanoseconds = (uint64_t) (_tolerance * NSEC_PER_SEC);

    dispatch_source_set_timer(
        self.timer,
        dispatch_time(DISPATCH_TIME_NOW, intervalInNanoseconds),
        intervalInNanoseconds,
        toleranceInNanoseconds
    );
}

- (void)schedule {
    [self resetTimerProperties];

    // Dispatch block should not retain the timer instance
    __weak IMUTLibTimer *weakSelf = self;
    dispatch_source_set_event_handler(self.timer, ^{
        [weakSelf timerFired];
    });

    dispatch_resume(self.timer);
}

- (void)fire {
    [self timerFired];
}

- (void)invalidate {
    if (!OSAtomicTestAndSetBarrier(7, &_timerFlags.timerIsInvalidated)) {
        dispatch_source_t timer = self.timer;
        dispatch_async(self.privateSerialQueue, ^{
            dispatch_source_cancel(timer);
        });
    }
}

#pragma mark Private

- (void)timerFired {
    if (OSAtomicAnd32OrigBarrier(1, &_timerFlags.timerIsInvalidated)) {
        return;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self.target performSelector:self.selector withObject:self];
#pragma clang diagnostic pop

    if (!self.repeats) {
        [self invalidate];
    }
}

@end
