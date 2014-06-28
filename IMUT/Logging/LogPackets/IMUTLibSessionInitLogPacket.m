#import <UIKit/UIKit.h>
#import "IMUTLibMain+Internal.h"
#import "IMUTLibSessionInitLogPacket.h"

@implementation IMUTLibSessionInitLogPacket

- (IMUTLibLogPacketType)logPacketType {
    return IMUTLibLogPacketTypeSessionInit;
}

- (NSDictionary *)parameters {
    UIDevice *currentDevice = [UIDevice currentDevice];
    UIScreen *screen = [UIScreen mainScreen];
    NSBundle *mainAppBundle = [NSBundle mainBundle];

    return @{
        @"modules" : [[[IMUTLibMain imut].config enabledModuleNames] allObjects],
        @"meta" : @{
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
        }
    };
}

@end
