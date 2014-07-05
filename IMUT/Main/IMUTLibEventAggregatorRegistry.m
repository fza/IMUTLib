#import "IMUTLibEventAggregatorRegistry.h"
#import "IMUTLibConstants.h"
#import "IMUTLibModuleRegistry.h"

@interface IMUTLibEventAggregatorRegistry ()

- (void)moduleRegistryWillFreeze:(NSNotification *)notification;

@end;

@implementation IMUTLibEventAggregatorRegistry {
    NSDictionary *_aggregatorBlocks;
}

SINGLETON

- (instancetype)init {
    if (self = [super init]) {
        _aggregatorBlocks = [NSMutableDictionary dictionary];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(moduleRegistryWillFreeze:)
                                                     name:IMUTLibModuleRegistryWillFreezeNotification
                                                   object:nil];
    }

    return self;
}

- (IMUTLibEventAggregatorBlock)aggregatorBlockForEventName:(NSString *)eventName {
    return [_aggregatorBlocks objectForKey:eventName];
}

- (void)registerEventAggregatorBlock:(IMUTLibEventAggregatorBlock)block forEventsWithNames:(NSSet *)eventNames {
    if (![IMUTLibModuleRegistry sharedInstance].frozen) {
        for (NSString *eventName in eventNames) {
            [self registerEventAggregatorBlock:block forEventName:eventName];
        };
    }
}

- (void)registerEventAggregatorBlock:(IMUTLibEventAggregatorBlock)block forEventName:(NSString *)eventName {
    NSAssert(![_aggregatorBlocks objectForKey:eventName], @"An aggregator block for events with name \"%@\" has already been registered.", eventName);
    NSAssert(![IMUTLibModuleRegistry sharedInstance].frozen, @"The registry is already frozen.");

    [(NSMutableDictionary *) _aggregatorBlocks setObject:block forKey:eventName];
}

#pragma mark Private

// Let the modules register their aggregator blocks
- (void)moduleRegistryWillFreeze:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    NSSet *eventModules = [[IMUTLibModuleRegistry sharedInstance] moduleInstancesWithType:IMUTLibModuleTypeEvented];
    for (IMUTLibModule *moduleInstance in eventModules) {
        [moduleInstance registerEventAggregatorBlocksInRegistry:self];
    }

    _aggregatorBlocks = [_aggregatorBlocks copy];
}

@end
