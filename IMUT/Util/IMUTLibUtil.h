#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface IMUTLibUtil : NSObject

// This is by far the most important function as it returns the system uptime with
// sub-millisecond precision (according to tests) and is guaranteed to return
// monolithic increasing data. It is independent of the system time, which is
// subject to run even backwards when certain events occur. (i.e. mobile cell change
// or manual reset by the user)
+ (NSTimeInterval)uptime;

// Unfortunately there are some cases where we need to intervene the main run loop
// to ensure no UI change may occur at the same time. This does, however, not
// guarantee that another application thread may change the proposed UI representation
// while the main thread is locked. These changes are incorporated into the visible
// application state when we release the lock.
+ (void)postNotificationOnMainThreadWithNotificationName:(NSString *)name object:(id)object waitUntilDone:(BOOL)waitUntilDone;

// Returns an alphanumeric string of arbitrary data
+ (NSString *)randomStringWithLength:(NSUInteger)length;

// Formats a date according to ISO 8601 including timezone info
+ (NSString *)iso8601StringFromDate:(NSDate *)date;

// Metadata of the IMUT, the device, platform and the application
+ (NSDictionary *)metadata;

@end
