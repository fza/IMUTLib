#import "IMUTLibUIViewControllerModule.h"
#import "IMUTLibConstants.h"
#import "IMUTLibUIViewControllerModuleConstants.h"
#import "IMUTLibUIViewControllerModule+SourceEventGeneration.h"
#import "IMUTLibMain.h"

@implementation IMUTLibUIViewControllerModule

+ (NSString *)moduleName {
    return kIMUTLibUIViewControllerModule;
}

+ (IMUTLibModuleType)moduleType {
    return IMUTLibModuleTypeEvented;
}

+ (NSDictionary *)defaultConfig {
    return @{
        kIMUTLibUIViewControllerModuleConfigUseFullClassName : numNO
    };
}

- (NSSet *)eventsWithCurrentState {
    [self ensureHierarchyAvailable];

    IMUTLibUIViewControllerChangeEvent *eventWithFrontMostViewController = [self sourceEventWithViewController:[self frontMostViewController]];
    if (eventWithFrontMostViewController) {
        return $(
            eventWithFrontMostViewController
        );
    }

    return nil;
}

- (void)start {
    [self startSourceEventGeneration];
}

- (void)pause {
    [self stopSourceEventGeneration];
}

- (void)resume {
    [self start];
}

- (void)terminate {
    [self pause];
}

- (IMUTLibUIViewControllerChangeEvent *)sourceEventWithViewController:(UIViewController *)viewController {
    static NSUInteger classNameRepresentation = 0;

    if (classNameRepresentation == 0) {
        if ([_config[kIMUTLibUIViewControllerModuleConfigUseFullClassName] boolValue]) {
            classNameRepresentation = IMUTLibUIViewControllerModuleClassNameRepresentationFull;
        } else {
            classNameRepresentation = IMUTLibUIViewControllerModuleClassNameRepresentationShort;
        }
    }

    if (viewController) {
        return [[IMUTLibUIViewControllerChangeEvent alloc] initWithViewControllerFullClassName:NSStringFromClass([viewController class])
                                                                             useRepresentation:(IMUTLibUIViewControllerModuleClassNameRepresentation) classNameRepresentation];
    }

    return nil;
}

#pragma mark IMUTLibModuleEventedProducer protocol

- (void)registerEventAggregatorBlocksInRegistry:(IMUTLibEventAggregatorRegistry *)registry {
    IMUTLibEventAggregatorBlock aggregator = ^IMUTLibAggregatorOPReturn(IMUTLibUIViewControllerChangeEvent *sourceEvent, IMUTLibUIViewControllerChangeEvent *lastPersistedSourceEvent, IMUTLibDeltaEntity **deltaEntity) {
        if (![[sourceEvent fullClassName] isEqualToString:[lastPersistedSourceEvent fullClassName]]) {
            *deltaEntity = [IMUTLibDeltaEntity deltaEntityWithSourceEvent:sourceEvent];
            (*deltaEntity).entityType = IMUTLibDeltaEntityTypeOther;

            return IMUTLibAggregationOperationEnqueue;
        }

        return IMUTLibAggregationOperationDequeue;
    };

    [registry registerEventAggregatorBlock:aggregator forEventName:kIMUTLibUIViewControllerChangeEvent];
}

@end

CONSTRUCTOR {
    [IMUTLibMain registerModuleWithClass:[IMUTLibUIViewControllerModule class]];
}
