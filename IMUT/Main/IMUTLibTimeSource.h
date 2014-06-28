#import <Foundation/Foundation.h>

@protocol IMUTLibTimeSourceDelegate

- (void)clockDidStartAtDate:(NSDate *)startDate;

- (void)clockDidStopAfterTimeInterval:(NSTimeInterval)timeInterval;

@end

@protocol IMUTLibTimeSource

// The receiver MUST call the methods defined in `IMUTLibTimeSourceDelegate` on the
// `timeSourceDelegate` whenever the state changes. Failure to do so will result
// in undefined behavior of the IMUT library.
@property(nonatomic, readwrite, weak) id <IMUTLibTimeSourceDelegate> timeSourceDelegate;

// A number used to decide which time source to choose if there are multiple
// clocks available. Higher numbers have higher precedence. The default screencast
// recorder returns 1024, the front camera recorder defaults to 512, the
// default time source implementation returns 0, thus the number must be greater
// than zero in order to be considered.
+ (NSNumber *)timeSourcePreference;

// A short descriptor
- (NSString *)timeSourceInfo;

// Get the absolute time when the clock started running. This may only be used
// for display purposes, but not for interval calculation as the underlying
// [NSDate date] may not be guaranteed to return monolithic increasing data.
- (NSDate *)startDate;

// Interval since clock start, which shall have at least millisecond precision.
// It must be guaranteed to return a value equal or greater the previous value.
- (NSTimeInterval)intervalSinceClockStart;

@optional
// Informs the receiver that the IMUT runtime decided to use it as primary time source.
- (void)denoteAsPrimaryTimeSource;

@end
