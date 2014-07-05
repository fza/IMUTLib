#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "IMUTLibSourceEvent.h"

@interface IMUTLibBatteryStateChangeEvent : NSObject <IMUTLibSourceEvent>

- (instancetype)initWithBatteryState:(UIDeviceBatteryState)batteryState;

- (UIDeviceBatteryState)batteryState;

- (NSString *)batteryStateString;

@end
