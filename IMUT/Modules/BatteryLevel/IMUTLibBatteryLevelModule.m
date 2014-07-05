#import <UIKit/UIKit.h>

#import "IMUTLibBatteryLevelModule.h"
#import "IMUTLibBatteryLevelChangeEvent.h"
#import "IMUTLibBatteryLevelModuleConstants.h"

@interface IMUTLibBatteryLevelModule ()

- (IMUTLibBatteryLevelChangeEvent *)eventWithCurrentBatteryLevel;

@end

@implementation IMUTLibBatteryLevelModule

#pragma mark IMUTLibModule class

+ (NSString *)moduleName {
    return kIMUTLibBatteryLevelModule;
}

+ (NSDictionary *)defaultConfig {
    return @{
        kIMUTLibBatteryLevelModuleConfigMinDeltaValue : @0.1 // 10.0%
    };
}

- (NSSet *)eventsWithInitialState {
    return $(
        [self eventWithCurrentBatteryLevel]
    );
}

- (void)registerEventAggregatorBlocksInRegistry:(IMUTLibEventAggregatorRegistry *)registry {
    IMUTLibEventAggregatorBlock aggregator = ^IMUTLibAggregatorOperation(IMUTLibBatteryLevelChangeEvent *sourceEvent, IMUTLibBatteryLevelChangeEvent *lastPersistedSourceEvent, IMUTLibPersistableEntity **deltaEntity) {
        if (!lastPersistedSourceEvent) {
            *deltaEntity = [IMUTLibPersistableEntity entityWithSourceEvent:sourceEvent];
            (*deltaEntity).entityType = IMUTLibPersistableEntityTypeAbsolute;

            return IMUTLibAggregationOperationEnqueue;
        } else {
            float newBatteryLevel = [sourceEvent batteryLevel];
            float oldBatteryLevel = [lastPersistedSourceEvent batteryLevel];
            float deltaBatteryLevel = newBatteryLevel - oldBatteryLevel;

            if (fabs(deltaBatteryLevel) >= [_config[kIMUTLibBatteryLevelModuleConfigMinDeltaValue] floatValue]) {
                NSDictionary *deltaParams = @{
                    kIMUTLibBatteryLevelChangeEventParamLevel : [NSNumber numberWithDouble:round(deltaBatteryLevel * 100.0) / 100.0]
                };

                *deltaEntity = [IMUTLibPersistableEntity entityWithParameters:deltaParams sourceEvent:sourceEvent];

                return IMUTLibAggregationOperationEnqueue;
            }
        }

        return IMUTLibAggregationOperationDequeue;
    };

    [registry registerEventAggregatorBlock:aggregator forEventName:kIMUTLibBatteryLevelChangeEvent];
}

#pragma mark IMUTLibPollingModule protocol

- (void)poll {
    [[IMUTLibSourceEventCollection sharedInstance] addSourceEvent:[self eventWithCurrentBatteryLevel]];
}

#pragma mark Private

- (IMUTLibBatteryLevelChangeEvent *)eventWithCurrentBatteryLevel {
    UIDevice *device = [UIDevice currentDevice];
    if (![device isBatteryMonitoringEnabled]) {
        device.batteryMonitoringEnabled = YES;
    }

    return [[IMUTLibBatteryLevelChangeEvent alloc] initWithBatteryLevel:device.batteryLevel];
}

@end

CONSTRUCTOR {
    [IMUTLibMain registerModuleWithClass:[IMUTLibBatteryLevelModule class]];
}
