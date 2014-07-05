#import <Foundation/Foundation.h>

@interface IMUTLibUtil : NSObject

// Unfortunately there are some cases where we need to intervene the main run loop
// to ensure no UI change may occur at the same time. This does, however, not
// guarantee that another application thread may change the proposed UI representation
// while the main thread is locked. These changes are incorporated into the visible
// application state when we release the lock.
+ (void)postNotification:(NSNotification *)notification
            onMainThread:(BOOL)onMainThread
           waitUntilDone:(BOOL)waitUntilDone;

+ (void)postNotificationName:(NSString *)name
                      object:(id)object
                    userInfo:(NSDictionary *)userInfo
                onMainThread:(BOOL)onMainThread
               waitUntilDone:(BOOL)waitUntilDone;

+ (void)postNotificationName:(NSString *)name
                      object:(id)object
                onMainThread:(BOOL)onMainThread
               waitUntilDone:(BOOL)waitUntilDone;

@end
