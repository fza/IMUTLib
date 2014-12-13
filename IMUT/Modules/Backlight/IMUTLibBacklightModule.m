#import <UIKit/UIKit.h>

#import "IMUTLibBacklightModule.h"
#import "IMUTLibBacklightChangeEvent.h"
#import "IMUTLibBacklightModuleConstants.h"

@interface IMUTLibBacklightModule ()

- (void)brightnessDidChange;

- (IMUTLibBacklightChangeEvent *)eventWithCurrentBrightness;

@end

@implementation IMUTLibBacklightModule

#pragma mark IMUTLibModule class

+ (NSString *)moduleName {
    return kIMUTLibBacklightModule;
}

+ (NSDictionary *)defaultConfig {
    return @{
        kIMUTLibBacklightModuleConfigMinDeltaValue : @0.1 // 10.0%
    };
}

- (NSSet *)eventsWithInitialState {
    return $(
        [self eventWithCurrentBrightness]
    );
}

- (void)startWithSession:(IMUTLibSession *)session {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(brightnessDidChange)
                                                 name:UIScreenBrightnessDidChangeNotification
                                               object:nil];
}

- (void)stopWithSession:(IMUTLibSession *)session {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)registerEventAggregatorBlocksInRegistry:(IMUTLibEventAggregatorRegistry *)registry {
    IMUTLibEventAggregatorBlock aggregator = ^IMUTLibAggregatorOperation(IMUTLibBacklightChangeEvent *sourceEvent, IMUTLibBacklightChangeEvent *lastPersistedSourceEvent, IMUTLibPersistableEntity **deltaEntity) {
        if (!lastPersistedSourceEvent) {
            *deltaEntity = [IMUTLibPersistableEntity entityWithSourceEvent:sourceEvent];
            (*deltaEntity).entityType = IMUTLibPersistableEntityTypeAbsolute;

            return IMUTLibAggregationOperationEnqueue;
        } else {
            CGFloat newBrightness = [sourceEvent brightness];
            CGFloat oldBrightness = [lastPersistedSourceEvent brightness];
            CGFloat deltaBrightness = newBrightness - oldBrightness;

            if (fabs(deltaBrightness) >= [_config[kIMUTLibBacklightModuleConfigMinDeltaValue] doubleValue]) {
                NSDictionary *deltaParams = @{
                    kIMUTLibBacklightChangeEventParamVal : @(round(deltaBrightness * 100.0) / 100.0)
                };

                *deltaEntity = [IMUTLibPersistableEntity entityWithParameters:deltaParams sourceEvent:sourceEvent];

                return IMUTLibAggregationOperationEnqueue;
            }
        }

        return IMUTLibAggregationOperationDequeue;
    };

    [registry registerEventAggregatorBlock:aggregator forEventName:kIMUTLibBacklightChangeEvent];
}

#pragma mark Private

- (void)brightnessDidChange {
    [[IMUTLibSourceEventCollection sharedInstance] addSourceEvent:[self eventWithCurrentBrightness]];
}

- (IMUTLibBacklightChangeEvent *)eventWithCurrentBrightness {
    return [[IMUTLibBacklightChangeEvent alloc] initWithBrightness:[UIScreen mainScreen].brightness];
}

@end

CONSTRUCTOR {
    [IMUTLibMain registerModuleWithClass:[IMUTLibBacklightModule class]];
}
