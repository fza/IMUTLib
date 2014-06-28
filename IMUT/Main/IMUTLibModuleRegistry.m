#import "IMUTLibDefaultTimeSource.h"
#import "IMUTLibConstants.h"
#import "IMUTLibMain+Internal.h"
#import "IMUTLibFunctions.h"
#import "IMUTLibUtil.h"
#import "IMUTLibAbstractModule.h"
#import "IMUTLibEventAggregator.h"

static dispatch_queue_t registryDispatchQueue;

@interface IMUTLibModuleRegistry ()

@property(atomic, readwrite, assign) BOOL frozen;
@property(nonatomic, readwrite, assign) BOOL haveMediaStream;
@property(nonatomic, readwrite, retain) NSObject <IMUTLibTimeSource> *bestTimeSource;

- (BOOL)enableModuleWithName:(NSString *)moduleName config:(NSDictionary *)moduleConfig;

- (void)freeze;

@end

@implementation IMUTLibModuleRegistry {
    NSDictionary *_allClasses;
    NSDictionary *_enabledInstances;
    NSDictionary *_enabledInstancesByType;
    NSInteger _bestTimeSourcePreference;
    NSDictionary *_moduleConfigs;
}

SINGLETON

+ (void)initialize {
    registryDispatchQueue = makeDispatchQueue(@"module-registry", DISPATCH_QUEUE_SERIAL, DISPATCH_QUEUE_PRIORITY_DEFAULT);
}

- (instancetype)init {
    if (self = [super init]) {
        // At initialization phase these are mutable and later degraded to non-mutable dicts
        _allClasses = [NSMutableDictionary dictionary];
        _enabledInstances = [NSMutableDictionary dictionary];
        _enabledInstancesByType = [NSMutableDictionary dictionary];
        _moduleConfigs = [NSMutableDictionary dictionary];

        self.frozen = NO;
        self.haveMediaStream = NO;
        self.bestTimeSource = nil;

        // Observe IMUT notifications
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        SEL notificationSelector = @selector(notifyModulesWithNotification:);
        for (NSString *notificationName in $(IMUTLibWillStartNotification, IMUTLibWillPauseNotification, IMUTLibDidResumeNotification, IMUTLibWillTerminateNotification)) {
            [defaultCenter addObserver:self
                              selector:notificationSelector
                                  name:notificationName
                                object:nil];
        }
    }

    return self;
}

- (NSObject <IMUTLibTimeSource> *)bestTimeSource {
    // As long as initialization of the IMUT library is not done, we don't know the best time source.
    if (!self.frozen) {
        return nil;
    }

    if (!_bestTimeSource) {
        _bestTimeSource = [IMUTLibDefaultTimeSource new];
    }

    return _bestTimeSource;
}

- (NSSet *)moduleInstancesWithType:(NSUInteger)moduleType {
    id set = _enabledInstancesByType[[NSNumber numberWithLong:moduleType]];

    return set ? (NSSet *) set : [NSSet set];
}

- (id <IMUTLibModule>)moduleInstanceWithName:(NSString *)name {
    return _enabledInstances[name];
}

- (void)enableModulesWithConfigs:(NSDictionary *)moduleConfigs {
    [moduleConfigs enumerateKeysAndObjectsUsingBlock:^(NSString *moduleName, NSDictionary *moduleConfig, BOOL *stop) {
        if (![self enableModuleWithName:moduleName config:moduleConfig]) {
            @throw [NSException exceptionWithName:IMUTLibFailedToEnableModuleException
                                           reason:[NSString stringWithFormat:@"IMUT was unable to initialize module \"%@\"",
                                                                             moduleName]
                                         userInfo:nil];
        }
    }];

    // Once the modules have been enabled, freeze the registry
    [self freeze];
}

- (BOOL)registerModuleWithClass:(Class)moduleClass {
    NSAssert(!self.frozen, @"Cannot add module with class \"%@\" as the module registry is already frozen.", NSStringFromClass(moduleClass));

    Class curClass = moduleClass;
    do {
        if (class_conformsToProtocol(curClass, @protocol(IMUTLibModule))) {
            NSString *moduleName = [moduleClass performSelector:@selector(moduleName)];
            [(NSMutableDictionary *) _allClasses setObject:moduleClass
                                                    forKey:moduleName];

            return YES;
        }
    } while ((curClass = class_getSuperclass(curClass)));

    NSAssert(false, @"The module identified by class \"%@\" is not conform with the \"IMUTLibModule\" protocol.", NSStringFromClass(moduleClass));

    // Silently fails if the module is not conform
    return NO;
}

- (void)notifyModulesWithNotification:(NSNotification *)notification {
    // Upon any notification the registry must be frozen
    if (!self.frozen) {
        [self freeze];
    }

    // The actual notification invocation block
    // We call the respective method on each module directly without a NSNotificationCenter to have
    // control over the execution order.
    __weak NSDictionary *weakInstances = _enabledInstances;
    dispatch_block_t notifyBlock = ^{
        NSObject <IMUTLibModule> *moduleInstance;
        for (NSString *moduleName in weakInstances) {
            moduleInstance = weakInstances[moduleName];
            if ([notification.name isEqualToString:IMUTLibWillStartNotification]) {
                if ([moduleInstance respondsToSelector:@selector(start)]) {
                    [moduleInstance start];
                }
            } else if ([notification.name isEqualToString:IMUTLibWillPauseNotification]) {
                if ([moduleInstance respondsToSelector:@selector(pause)]) {
                    [moduleInstance pause];
                }
            } else if ([notification.name isEqualToString:IMUTLibDidResumeNotification]) {
                if ([moduleInstance respondsToSelector:@selector(resume)]) {
                    [moduleInstance resume];
                }
            } else if ([notification.name isEqualToString:IMUTLibWillTerminateNotification]) {
                if ([moduleInstance respondsToSelector:@selector(terminate)]) {
                    [moduleInstance terminate];
                }
            }
        }
    };

    // Pause and Terminate notifications should be invoked synchronously, others asynchronously.
    // The key idea is to invoke the modules in a dedicated dispatch queue i.e. thread to increase
    // application performance.
    if (notification.name == IMUTLibWillPauseNotification || notification.name == IMUTLibWillTerminateNotification) {
        dispatch_sync(registryDispatchQueue, notifyBlock);
    } else {
        dispatch_async(registryDispatchQueue, notifyBlock);
    }
}

- (NSDictionary *)configForModuleWithName:(NSString *)moduleName {
    if (self.frozen) {
        return _moduleConfigs[moduleName];
    }

    return nil;
}

#pragma mark Private

- (BOOL)enableModuleWithName:(NSString *)moduleName config:(NSDictionary *)moduleConfig {
    // Already enabled?
    if ([_enabledInstances objectForKey:moduleName]) {
        return YES;
    }

    Class moduleClass = [_allClasses objectForKey:moduleName];
    if (moduleClass) {
        // Collect module config
        if ([moduleClass respondsToSelector:@selector(defaultConfig)]) {
            NSMutableDictionary *tempConfig = [[moduleClass performSelector:@selector(defaultConfig)] mutableCopy];
            [tempConfig addEntriesFromDictionary:moduleConfig];
            moduleConfig = [tempConfig copy];
            ((NSMutableDictionary *) _moduleConfigs)[moduleName] = moduleConfig;
        }

        // Create module instance
        id moduleInstance = [[moduleClass alloc] initWithConfig:moduleConfig];

        if (moduleInstance) {
            // Retain the instance
            [(NSMutableDictionary *) _enabledInstances setObject:moduleInstance forKey:moduleName];

            // Classify by module type(s)
            BOOL hasValidModuleType = NO;
            IMUTLibModuleType moduleType = [moduleClass moduleType];
            for (NSUInteger checkType = 1; checkType < IMUTLibModuleTypeAll; checkType *= 2) {
                if (moduleType & checkType) {
                    hasValidModuleType = YES;
                    NSNumber *checkModuleTypeNumber = [NSNumber numberWithLong:checkType];
                    NSMutableSet *enabledInstancesForType = _enabledInstancesByType[checkModuleTypeNumber];
                    if (!enabledInstancesForType) {
                        enabledInstancesForType = [NSMutableSet set];
                        ((NSMutableDictionary *) _enabledInstancesByType)[checkModuleTypeNumber] = enabledInstancesForType;
                    }
                    [enabledInstancesForType addObject:moduleInstance];
                }
            }

            // Check for valid module type
            NSAssert(hasValidModuleType, @"The module \"%@\" does not designate a valid module type.", moduleName);

            // Check for event producer protocol
            if (moduleType & IMUTLibModuleTypeEvented) {
                BOOL isConformEventAggregator = NO;
                Class curClass = moduleClass;
                do {
                    if (class_conformsToProtocol(curClass, @protocol(IMUTLibEventAggregator))) {
                        isConformEventAggregator = YES;

                        break;
                    }
                } while ((curClass = class_getSuperclass(curClass)));

                NSAssert(isConformEventAggregator, @"The module \"%@\" does not implement the IMUTLibEventAggregator protocol.", moduleName);
            }

            // Check if it is a recorder
            if (!self.haveMediaStream && moduleType & IMUTLibModuleTypeStream) {
                self.haveMediaStream = YES;
            }

            // Check if it is a time source
            Class curClass = moduleClass;
            do {
                if (class_conformsToProtocol(curClass, @protocol(IMUTLibTimeSource))) {
                    NSInteger preference = [(NSNumber *) [moduleClass performSelector:@selector(timeSourcePreference)] intValue];
                    if (preference > _bestTimeSourcePreference) {
                        _bestTimeSourcePreference = preference;
                        self.bestTimeSource = moduleInstance;
                    }

                    break;
                }
            } while ((curClass = class_getSuperclass(curClass)));

            IMUTLogMain(@"Using module \"%@\"", moduleName);

            return YES;
        }
    }

    IMUTLogDebug(@"Unable to enable module \"%@\".", moduleName);

    return NO;
}

- (void)freeze {
    @synchronized (self) {
        if (!self.frozen) {
            self.frozen = YES;

            _allClasses = [_allClasses copy];
            _enabledInstances = [_enabledInstances copy];
            _enabledInstancesByType = [_enabledInstancesByType copy];
            _moduleConfigs = [_moduleConfigs copy];

            [IMUTLibUtil postNotificationOnMainThreadWithNotificationName:IMUTLibModuleRegistryDidFreezeNotification
                                                                   object:self
                                                            waitUntilDone:YES];
        }
    }
}

@end
