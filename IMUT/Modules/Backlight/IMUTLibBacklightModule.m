#import <UIKit/UIKit.h>
#import "IMUTLibBacklightModule.h"
#import "IMUTLibBacklightChangeEvent.h"
#import "IMUTLibBacklightModuleConstants.h"
#import "IMUTLibSourceEventQueue.h"
#import "IMUTLibMain.h"

@interface IMUTLibBacklightModule ()

- (void)brightnessDidChange;

- (IMUTLibBacklightChangeEvent *)eventWithCurrentBrightness;

@end

@implementation IMUTLibBacklightModule

#pragma mark IMUTLibModule protocol

+ (NSString *)moduleName {
    return kIMUTLibBacklightModule;
}

+ (NSDictionary *)defaultConfig {
    return @{
        kIMUTLibBacklightModuleConfigMinDeltaValue : @0.1 // 10.0%
    };
}

- (NSSet *)eventsWithCurrentState {
    return $(
        [self eventWithCurrentBrightness]
    );
}

- (void)start {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(brightnessDidChange)
                                                 name:UIScreenBrightnessDidChangeNotification
                                               object:nil];
}

- (void)pause {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)resume {
    [self start];
}

- (void)terminate {
    [self pause];
}

#pragma mark IMUTLibModuleEventedProducer protocol

- (void)registerEventAggregatorBlocksInRegistry:(IMUTLibEventAggregatorRegistry *)registry {
    IMUTLibEventAggregatorBlock aggregator = ^IMUTLibAggregatorOPReturn(IMUTLibBacklightChangeEvent *sourceEvent, IMUTLibBacklightChangeEvent *lastPersistedSourceEvent, IMUTLibDeltaEntity **deltaEntity) {
        CGFloat newBrightness = [sourceEvent brightness];
        CGFloat oldBrightness = [lastPersistedSourceEvent brightness];
        CGFloat deltaBrightness = newBrightness - oldBrightness;

        if (fabs(deltaBrightness) >= [_config[kIMUTLibBacklightModuleConfigMinDeltaValue] doubleValue]) {
            NSDictionary *deltaParams = @{
                kIMUTLibBacklightChangeEventParamVal : [NSNumber numberWithDouble:round(deltaBrightness * 100.0) / 100.0]
            };

            *deltaEntity = [IMUTLibDeltaEntity deltaEntityWithParameters:deltaParams
                                                             sourceEvent:sourceEvent];

            return IMUTLibAggregationOperationEnqueue;
        }

        return IMUTLibAggregationOperationDequeue;
    };

    [registry registerEventAggregatorBlock:aggregator forEventName:kIMUTLibBacklightChangeEvent];
}

#pragma mark Private

- (void)brightnessDidChange {
    [[IMUTLibSourceEventQueue sharedInstance] enqueueSourceEvent:[self eventWithCurrentBrightness]];
}

- (IMUTLibBacklightChangeEvent *)eventWithCurrentBrightness {
    return [[IMUTLibBacklightChangeEvent alloc] initWithBrightness:[UIScreen mainScreen].brightness];
}

@end

CONSTRUCTOR {
    [IMUTLibMain registerModuleWithClass:[IMUTLibBacklightModule class]];
}
