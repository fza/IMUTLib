#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface IMUTLibUtil : NSObject

// Unfortunately there are some cases where we need to intervene the main run loop
// to ensure no UI change may occur at the same time. This does, however, not
// guarantee that another application thread may change the proposed UI representation
// while the main thread is locked. These changes are incorporated into the visible
// application state when we release the lock.
+ (void)postNotificationOnMainThreadWithNotificationName:(NSString *)name
                                                  object:(id)object
                                                userInfo:(NSDictionary *)userInfo
                                           waitUntilDone:(BOOL)waitUntilDone;

+ (void)postNotificationOnMainThreadWithNotificationName:(NSString *)name
                                                  object:(id)object
                                           waitUntilDone:(BOOL)waitUntilDone;

@end
