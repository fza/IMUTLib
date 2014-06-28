#import <sys/sysctl.h>
#import <UIKit/UIKit.h>
#import "IMUTLibUtil.h"
#import "IMUTLibMain.h"
#import "Macros.h"

@implementation IMUTLibUtil

+ (NSTimeInterval)uptime {
    return [[NSProcessInfo processInfo] systemUptime];
}

+ (void)postNotificationOnMainThreadWithNotificationName:(NSString *)name object:(id)object waitUntilDone:(BOOL)waitUntilDone {
    NSNotification *startNotification = [NSNotification notificationWithName:name
                                                                      object:object];

    [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:)
                                                           withObject:startNotification
                                                        waitUntilDone:waitUntilDone];
}

// @see http://stackoverflow.com/questions/2633801/generate-a-random-alphanumeric-string-in-cocoa
+ (NSString *)randomStringWithLength:(NSUInteger)length {
    static NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

    NSMutableString *randomString = [NSMutableString stringWithCapacity:length];
    for (NSUInteger i = 0; i < length; i++) {
        [randomString appendFormat:@"%C",
                                   [letters characterAtIndex:arc4random_uniform((unsigned int) [letters length])]];
    }

    return randomString;
}

+ (NSString *)iso8601StringFromDate:(NSDate *)date {
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.timeZone = [NSTimeZone localTimeZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    return [dateFormatter stringFromDate:date];
}

+ (NSDictionary *)metadata {
    UIDevice *currentDevice = [UIDevice currentDevice];
    UIScreen *screen = [UIScreen mainScreen];
    NSBundle *mainAppBundle = [NSBundle mainBundle];

    return @{
        @"imut-version" : [IMUTLibMain imutVersion],
        @"platform-name" : currentDevice.systemName,
        @"platform-version" : currentDevice.systemVersion,
        @"device-model" : currentDevice.model,
        @"app-id" : (NSString *) [mainAppBundle objectForInfoDictionaryKey:@"CFBundleIdentifier"],
        @"app-version" : (NSString *) [mainAppBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
        @"screen-size" : @{
            @"scale" : [NSNumber numberWithDouble:screen.scale],
            @"points" : @{
                @"width" : [NSNumber numberWithInteger:(int) screen.bounds.size.width],
                @"height" : [NSNumber numberWithInteger:(int) screen.bounds.size.height],
            },
            @"device" : @{
                @"width" : [NSNumber numberWithInteger:(int) (screen.bounds.size.width * screen.scale)],
                @"height" : [NSNumber numberWithInteger:(int) (screen.bounds.size.height * screen.scale)]
            }
        },
        @"app-frame-size-points" : @{
            @"width" : [NSNumber numberWithInteger:(int) screen.applicationFrame.size.width],
            @"height" : [NSNumber numberWithInteger:(int) screen.applicationFrame.size.height]
        }
    };
}

@end
