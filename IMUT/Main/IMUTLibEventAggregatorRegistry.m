#import "IMUTLibEventAggregatorRegistry.h"
#import "IMUTLibConstants.h"
#import "IMUTLibModuleRegistry.h"
#import "IMUTLibEventAggregator.h"

@interface IMUTLibEventAggregatorRegistry ()

- (void)imutDidStart:(NSNotification *)notification;

- (void)imutRegistryDidFreeze:(NSNotification *)notification;

@end;

@implementation IMUTLibEventAggregatorRegistry {
    NSDictionary *_aggregatorBlocks;
    BOOL _frozen;
}

SINGLETON

+ (void)initialize {
    IMUTLibEventAggregatorRegistry *sharedInstance = [self sharedInstance];
    [[NSNotificationCenter defaultCenter] addObserver:sharedInstance
                                             selector:@selector(imutRegistryDidFreeze:)
                                                 name:IMUTLibModuleRegistryDidFreezeNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:sharedInstance
                                             selector:@selector(imutDidStart:)
                                                 name:IMUTLibWillStartNotification
                                               object:nil];
}

- (instancetype)init {
    if (self = [super init]) {
        _aggregatorBlocks = [NSMutableDictionary dictionary];
        _frozen = NO;
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

// Degrade aggregator blocks dictionary to free some memory
- (void)imutDidStart:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IMUTLibWillStartNotification
                                                  object:nil];

    // Wrapping this in a once token, though the start event should only occur once
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Degrade aggregator blocks dictionary (optimization)
        _aggregatorBlocks = [_aggregatorBlocks copy];
    });
}

// Let the modules register their aggregator blocks
- (void)imutRegistryDidFreeze:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IMUTLibModuleRegistryDidFreezeNotification
                                                  object:nil];

    for (id moduleInstance in [[IMUTLibModuleRegistry sharedInstance] moduleInstancesWithType:IMUTLibModuleTypeEvented]) {
        Class curClass = [moduleInstance class];
        do {
            if (class_conformsToProtocol(curClass, @protocol(IMUTLibEventAggregator))) {
                [moduleInstance registerEventAggregatorBlocksInRegistry:self];
                break;
            }
        } while ((curClass = [curClass superclass]));
    }

    _frozen = YES;
}

@end