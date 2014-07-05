#import "IMUTLibUIViewControllerModule.h"
#import "IMUTLibUIViewControllerModule+SourceEventGeneration.h"
#import "IMUTLibUIViewControllerModuleConstants.h"

#import "IMUTLibConstants.h"

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

- (NSSet *)eventsWithInitialState {
    [self ensureHierarchyAvailable];

    IMUTLibUIViewControllerChangeEvent *sourceEvent = [self sourceEventWithViewController:[self frontMostViewController]];

    return sourceEvent ? $(sourceEvent) : nil;
}

- (void)startWithSession:(IMUTLibSession *)session {
    [self startSourceEventGeneration];
}

- (void)stopWithSession:(IMUTLibSession *)session {
    [self stopSourceEventGeneration];
}

#pragma mark IMUTLibModuleEventedProducer protocol

- (void)registerEventAggregatorBlocksInRegistry:(IMUTLibEventAggregatorRegistry *)registry {
    IMUTLibEventAggregatorBlock aggregator = ^IMUTLibAggregatorOperation(IMUTLibUIViewControllerChangeEvent *sourceEvent, IMUTLibUIViewControllerChangeEvent *lastPersistedSourceEvent, IMUTLibPersistableEntity **deltaEntity) {
        if (!lastPersistedSourceEvent || ![[sourceEvent fullClassName] isEqualToString:[lastPersistedSourceEvent fullClassName]]) {
            *deltaEntity = [IMUTLibPersistableEntity entityWithSourceEvent:sourceEvent];
            (*deltaEntity).entityType = IMUTLibPersistableEntityTypeOther;

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
