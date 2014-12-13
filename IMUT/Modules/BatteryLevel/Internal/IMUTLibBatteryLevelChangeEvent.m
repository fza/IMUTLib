#import "IMUTLibBatteryLevelChangeEvent.h"
#import "IMUTLibBatteryLevelModuleConstants.h"

@implementation IMUTLibBatteryLevelChangeEvent {
    float _batteryLevel;
}

- (instancetype)initWithBatteryLevel:(float)batteryLevel {
    if (self = [super init]) {
        if (batteryLevel < 0 || batteryLevel > 1) {
            return nil;
        }

        _batteryLevel = batteryLevel;

        return self;
    }

    return nil;
}

- (float)batteryLevel {
    return _batteryLevel;
}

#pragma mark IMUTLibSourceEvent protocol

- (NSString *)eventName {
    return kIMUTLibBatteryLevelChangeEvent;
}

- (NSDictionary *)parameters {
    return @{
        kIMUTLibBatteryLevelChangeEventParamLevel : @(round(_batteryLevel * 10.0) / 10.0)
    };
}

@end
