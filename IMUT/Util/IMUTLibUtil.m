#import <UIKit/UIKit.h>
#import "IMUTLibUtil.h"
#import "IMUTLibMain.h"

@implementation IMUTLibUtil

+ (void)postNotificationOnMainThreadWithNotificationName:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo waitUntilDone:(BOOL)waitUntilDone {
    NSNotification *startNotification = [NSNotification notificationWithName:name
                                                                      object:object
                                                                    userInfo:userInfo];

    [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:)
                                                           withObject:startNotification
                                                        waitUntilDone:waitUntilDone];
}

+ (void)postNotificationOnMainThreadWithNotificationName:(NSString *)name object:(id)object waitUntilDone:(BOOL)waitUntilDone {
    NSNotification *startNotification = [NSNotification notificationWithName:name
                                                                      object:object];

    [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:)
                                                           withObject:startNotification
                                                        waitUntilDone:waitUntilDone];
}

@end
