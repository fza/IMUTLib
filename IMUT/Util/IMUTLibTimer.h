#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

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

- (void)runOutAndInvalidateWaitUntilDone:(BOOL)waitUntilDone;

- (void)setInvaliationHandler:(void (^)(void))handler;

- (void)linkWithTimebase:(CMTimebaseRef)timebase;

- (BOOL)pause;

- (BOOL)resume;

- (BOOL)resumeAfter:(NSTimeInterval)interval;

- (void)fireAndPause;

@end

// Convenience function
IMUTLibTimer *makeRepeatingTimer(NSTimeInterval timeInterval, id target, SEL selector, dispatch_queue_t dispatchQueue, BOOL schedule);
