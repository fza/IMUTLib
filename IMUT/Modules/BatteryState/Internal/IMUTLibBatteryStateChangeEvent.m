#import <UIKit/UIKit.h>

#import "IMUTLibBatteryStateChangeEvent.h"
#import "IMUTLibBatteryStateConstants.h"
#import "IMUTLibConstants.h"

@interface IMUTLibBatteryStateChangeEvent ()

- (BOOL)isValidBatteryState:(UIDeviceBatteryState)batteryState;

@end

@implementation IMUTLibBatteryStateChangeEvent {
    UIDeviceBatteryState _batteryState;
}

- (instancetype)initWithBatteryState:(UIDeviceBatteryState)batteryState {
    if (self = [super init]) {
        if ([self isValidBatteryState:batteryState]) {
            _batteryState = batteryState;

            return self;
        }
    }

    return nil;
}

- (UIDeviceBatteryState)batteryState {
    return _batteryState;
}

- (NSString *)batteryStateString {
    switch (_batteryState) {
        case UIDeviceBatteryStateUnplugged:
            return kIMUTLibBatteryStateChangeEventParamStateValUnplugged;

        case UIDeviceBatteryStateCharging:
            return kIMUTLibBatteryStateChangeEventParamStateValCharging;

        case UIDeviceBatteryStateFull:
            return kIMUTLibBatteryStateChangeEventParamStateValFull;

        default:
            return kUnknown;
    }
}

#pragma mark IMUTLibSourceEvent protocol

- (NSString *)eventName {
    return kIMUTLibBatteryStateChangeEvent;
}

- (NSDictionary *)parameters {
    return @{
        kIMUTLibBatteryStateChangeEventParamState : [self batteryStateString]
    };
}

#pragma mark Private

- (BOOL)isValidBatteryState:(UIDeviceBatteryState)batteryState {
    return batteryState == UIDeviceBatteryStateUnplugged ||
        batteryState == UIDeviceBatteryStateCharging ||
        batteryState == UIDeviceBatteryStateFull;
}

@end
