#import <Foundation/Foundation.h>

@protocol IMUTLibSessionTimer

// A number used to decide which time source to choose if there are multiple
// clocks available. Higher numbers have higher precedence. The default screencast
// recorder returns 1024, the front camera recorder defaults to 512, the
// default time source implementation returns 0, thus the number must be greater
// than zero in order to be considered.
+ (NSUInteger)preference;

// A short descriptor (borrowed from <NSObject>)
+ (NSString *)description;

// Interval since clock start, which shall have at least millisecond precision.
// It must be guaranteed to return monolithic increasing values. If the
// time source is stopped it shall return the duration of the last session.
- (NSTimeInterval)duration;

// Called when the time source should set its time base and start running.
// Return NO if any error occured.
- (void)startTickingWithCompletionBlock:(void (^)(BOOL started))completionBlock;

// Called when the timer should stop
- (void)stopTickingWithCompletionBlock:(void (^)(BOOL stopped))completionBlock;

@end
