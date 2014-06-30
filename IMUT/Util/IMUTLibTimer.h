#import <Foundation/Foundation.h>

@interface IMUTLibTimer : NSObject

@property(nonatomic, readwrite) NSTimeInterval timeInterval;
@property(nonatomic, readwrite) NSTimeInterval tolerance;
@property(nonatomic, readonly) BOOL scheduled;
@property(nonatomic, readonly) BOOL paused;
@property(nonatomic, readonly) BOOL invalidated;

+ (instancetype)scheduleTimerWithTimeInterval:(NSTimeInterval)timeInterval
                                       target:(id)target
                                     selector:(SEL)selector
                                      repeats:(BOOL)repeats
                                dispatchQueue:(dispatch_queue_t)dispatchQueue;

+ (instancetype)timerWithTimeInterval:(NSTimeInterval)timeInterval
                               target:(id)target
                             selector:(SEL)selector
                              repeats:(BOOL)repeats
                        dispatchQueue:(dispatch_queue_t)dispatchQueue;

- (instancetype)initWithTimeInterval:(NSTimeInterval)timeInterval
                              target:(id)target
                            selector:(SEL)selector
                             repeats:(BOOL)repeats
                       dispatchQueue:(dispatch_queue_t)dispatchQueue;

- (BOOL)schedule;

- (void)invalidate;

- (BOOL)pause;

- (BOOL)resume;

- (void)fireAndPause;

@end

// Convenience function
IMUTLibTimer *repeatingTimer(NSTimeInterval timeInterval, id target, SEL selector, dispatch_queue_t dispatchQueue, BOOL schedule);
