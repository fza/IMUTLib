#import <UIKit/UIKit.h>

#import "IMUTLibBatteryStateModule.h"
#import "IMUTLibBatteryStateChangeEvent.h"
#import "IMUTLibBatteryStateConstants.h"

@interface IMUTLibBatteryStateModule ()

- (IMUTLibBatteryStateChangeEvent *)eventWithCurrentBatteryState;

@end

@implementation IMUTLibBatteryStateModule

#pragma mark IMUTLibModule class

+ (NSString *)moduleName {
    return kIMUTLibBatteryStateModule;
}

- (NSSet *)eventsWithInitialState {
    IMUTLibBatteryStateChangeEvent *sourceEvent = [self eventWithCurrentBatteryState];

    return sourceEvent ? $(sourceEvent) : nil;
}

- (void)registerEventAggregatorBlocksInRegistry:(IMUTLibEventAggregatorRegistry *)registry {
    IMUTLibEventAggregatorBlock aggregator = ^IMUTLibAggregatorOperation(IMUTLibBatteryStateChangeEvent *sourceEvent, IMUTLibBatteryStateChangeEvent *lastPersistedSourceEvent, IMUTLibPersistableEntity **deltaEntity) {
        if (!lastPersistedSourceEvent || sourceEvent.batteryState != lastPersistedSourceEvent.batteryState) {
            *deltaEntity = [IMUTLibPersistableEntity entityWithSourceEvent:sourceEvent];
            (*deltaEntity).entityType = IMUTLibPersistableEntityTypeStatus;

            return IMUTLibAggregationOperationEnqueue;
        }

        return IMUTLibAggregationOperationDequeue;
    };

    [registry registerEventAggregatorBlock:aggregator forEventName:kIMUTLibBatteryStateChangeEvent];
}

#pragma mark IMUTLibPollingModule protocol

- (void)poll {
    [[IMUTLibSourceEventCollection sharedInstance] addSourceEvent:[self eventWithCurrentBatteryState]];
}

#pragma mark Private

- (IMUTLibBatteryStateChangeEvent *)eventWithCurrentBatteryState {
    UIDevice *device = [UIDevice currentDevice];
    if (![device isBatteryMonitoringEnabled]) {
        device.batteryMonitoringEnabled = YES;
    }

    return [[IMUTLibBatteryStateChangeEvent alloc] initWithBatteryState:device.batteryState];
}

@end

CONSTRUCTOR {
    [IMUTLibMain registerModuleWithClass:[IMUTLibBatteryStateModule class]];
}
