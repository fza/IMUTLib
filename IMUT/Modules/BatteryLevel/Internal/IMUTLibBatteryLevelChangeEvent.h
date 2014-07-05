#import <Foundation/Foundation.h>

#import "IMUTLibSourceEvent.h"

@interface IMUTLibBatteryLevelChangeEvent : NSObject <IMUTLibSourceEvent>

- (instancetype)initWithBatteryLevel:(float)batteryLevel;

- (float)batteryLevel;

@end
