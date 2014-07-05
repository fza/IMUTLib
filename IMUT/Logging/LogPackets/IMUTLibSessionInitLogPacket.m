#import <UIKit/UIKit.h>
#import "IMUTLibSessionInitLogPacket.h"
#import "IMUTLibModuleRegistry.h"
#import "IMUTLibMain+Internal.h"

@implementation IMUTLibSessionInitLogPacket

- (IMUTLibLogPacketType)logPacketType {
    return IMUTLibLogPacketTypeSessionInit;
}

- (NSDictionary *)parameters {
    UIDevice *currentDevice = [UIDevice currentDevice];
    UIScreen *screen = [UIScreen mainScreen];
    NSBundle *mainAppBundle = [NSBundle mainBundle];

    return @{
        @"modules" : [[IMUTLibModuleRegistry sharedInstance].enabledModulesByName allObjects],
        @"meta" : @{
            @"imut-version" : [IMUTLibMain imutVersion],
            @"platform-name" : currentDevice.systemName,
            @"platform-version" : currentDevice.systemVersion,
            @"device-model" : currentDevice.model,
            @"app-id" : (NSString *) [mainAppBundle objectForInfoDictionaryKey:@"CFBundleIdentifier"],
            @"app-version" : (NSString *) [mainAppBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
            @"screen-size" : @{
                @"scale" : @(screen.scale),
                @"points" : @{
                    @"width" : @((int) screen.bounds.size.width),
                    @"height" : @((int) screen.bounds.size.height),
                },
                @"device" : @{
                    @"width" : @((int) (screen.bounds.size.width * screen.scale)),
                    @"height" : @((int) (screen.bounds.size.height * screen.scale))
                }
            },
            @"app-frame-size-points" : @{
                @"width" : @((int) screen.applicationFrame.size.width),
                @"height" : @((int) screen.applicationFrame.size.height)
            }
        }
    };
}

@end
