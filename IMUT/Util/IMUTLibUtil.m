#import "IMUTLibUtil.h"
#import "IMUTLibFunctions.h"

@implementation IMUTLibUtil

+ (void)postNotification:(NSNotification *)notification onMainThread:(BOOL)onMainThread waitUntilDone:(BOOL)waitUntilDone {
    if (onMainThread) {
        [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:)
                                                               withObject:notification
                                                            waitUntilDone:waitUntilDone];
    } else {
        dispatch_async(mainImutDispatchQueue(DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
            [[NSNotificationCenter defaultCenter] performSelector:@selector(postNotification:)
                                                         onThread:[NSThread currentThread]
                                                       withObject:notification
                                                    waitUntilDone:waitUntilDone];
        });
    }
}

+ (void)postNotificationName:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo onMainThread:(BOOL)onMainThread waitUntilDone:(BOOL)waitUntilDone {
    NSNotification *notification = [NSNotification notificationWithName:name
                                                                 object:object
                                                               userInfo:userInfo];

    [self postNotification:notification
              onMainThread:onMainThread
             waitUntilDone:waitUntilDone];
}

+ (void)postNotificationName:(NSString *)name object:(id)object onMainThread:(BOOL)onMainThread waitUntilDone:(BOOL)waitUntilDone {
    NSNotification *notification = [NSNotification notificationWithName:name
                                                                 object:object];

    [self postNotification:notification
              onMainThread:onMainThread
             waitUntilDone:waitUntilDone];
}

@end
