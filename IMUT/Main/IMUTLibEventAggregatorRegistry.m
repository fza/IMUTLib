#import "IMUTLibEventAggregatorRegistry.h"
#import "IMUTLibConstants.h"
#import "IMUTLibModuleRegistry.h"
#import "IMUTLibEventAggregator.h"

@interface IMUTLibEventAggregatorRegistry ()

- (void)moduleRegistryDidFreeze:(NSNotification *)notification;

@end;

@implementation IMUTLibEventAggregatorRegistry {
    NSDictionary *_aggregatorBlocks;
    BOOL _frozen;
}

SINGLETON

- (instancetype)init {
    if (self = [super init]) {
        _aggregatorBlocks = [NSMutableDictionary dictionary];
        _frozen = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(moduleRegistryDidFreeze:)
                                                     name:IMUTLibModuleRegistryDidFreezeNotification
                                                   object:nil];
    }

    return self;
}

- (IMUTLibEventAggregatorBlock)aggregatorBlockForEventName:(NSString *)eventName {
    return [_aggregatorBlocks objectForKey:eventName];
}

- (void)registerEventAggregatorBlock:(IMUTLibEventAggregatorBlock)block forEventsWithNames:(NSSet *)eventNames {
    if (!_frozen) {
        for (NSString *eventName in eventNames) {
            [self registerEventAggregatorBlock:block forEventName:eventName];
        };
    }
}

- (void)registerEventAggregatorBlock:(IMUTLibEventAggregatorBlock)block forEventName:(NSString *)eventName {
    NSAssert(![_aggregatorBlocks objectForKey:eventName], @"An aggregator block for events with name \"%@\" has already been registered.", eventName);

    [(NSMutableDictionary *) _aggregatorBlocks setObject:block forKey:eventName];
}

#pragma mark Private

// Let the modules register their aggregator blocks
- (void)moduleRegistryDidFreeze:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    for (id moduleInstance in [[IMUTLibModuleRegistry sharedInstance] moduleInstancesWithType:IMUTLibModuleTypeEvented]) {
        Class curClass = [moduleInstance class];
        do {
            if (class_conformsToProtocol(curClass, @protocol(IMUTLibEventAggregator))) {
                [moduleInstance registerEventAggregatorBlocksInRegistry:self];
                break;
            }
        } while ((curClass = [curClass superclass]));
    }
    
    _aggregatorBlocks = [_aggregatorBlocks copy];

    _frozen = YES;
}

@end
