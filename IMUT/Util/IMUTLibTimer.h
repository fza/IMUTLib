#import <Foundation/Foundation.h>

@interface IMUTLibTimer : NSObject

@property(atomic, readwrite) NSTimeInterval timeInterval;
@property(atomic, readwrite) NSTimeInterval tolerance;

- (id)initWithTimeInterval:(NSTimeInterval)timeInterval
                    target:(id)target
                  selector:(SEL)selector
                  userInfo:(id)userInfo
                   repeats:(BOOL)repeats
             dispatchQueue:(dispatch_queue_t)dispatchQueue;

+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)timeInterval
                                        target:(id)target
                                      selector:(SEL)selector
                                      userInfo:(id)userInfo
                                       repeats:(BOOL)repeats
                                 dispatchQueue:(dispatch_queue_t)dispatchQueue;

- (void)resetTimerProperties;

- (void)schedule;

- (void)fire;

- (void)invalidate;

- (id)userInfo;

@end

// Convenience function
IMUTLibTimer *repeatingTimer(NSTimeInterval timeInterval, id target, SEL selector, dispatch_queue_t dispatchQueue);
