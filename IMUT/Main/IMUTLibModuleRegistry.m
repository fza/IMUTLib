#import "IMUTLibModuleRegistry.h"
#import "IMUTLibConstants.h"
#import "IMUTLibFunctions.h"
#import "IMUTLibPollingModule.h"
#import "IMUTLibUtil.h"
#import "IMUTLibDefaultSessionTimer.h"

@interface IMUTLibModuleRegistry ()

@property(nonatomic, readwrite, retain) NSSet *enabledModulesByName;
@property(nonatomic, readwrite, retain) NSObject <IMUTLibSessionTimer> *timer;

- (BOOL)enableModuleWithName:(NSString *)moduleName config:(NSDictionary *)moduleConfig;

- (void)freeze;

@end

@implementation IMUTLibModuleRegistry {
    Class _sessionTimerClass;
    NSDictionary *_registeredModuleClasses;
    NSDictionary *_enabledInstancesByName;
    NSDictionary *_enabledInstancesByType;
    NSDictionary *_moduleConfigs;

    dispatch_queue_t _dispatch_queue;
}

SINGLETON

- (instancetype)init {
    if (self = [super init]) {
        // At initialization phase these are mutable and later degraded to non-mutable dicts
        _enabledModulesByName = [NSMutableSet set];
        _pollingModuleInstances = [NSMutableSet set];
        _registeredModuleClasses = [NSMutableDictionary dictionary];
        _enabledInstancesByName = [NSMutableDictionary dictionary];
        _moduleConfigs = [NSMutableDictionary dictionary];

        _enabledInstancesByType = @{
            @(IMUTLibModuleTypeStream) : [NSMutableSet set],
            @(IMUTLibModuleTypeEvented) : [NSMutableSet set]
        };

        _sessionTimerClass = [IMUTLibDefaultSessionTimer class];
        _frozen = NO;

        // Observe IMUT notifications
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        SEL notificationSelector = @selector(notifyModulesWithNotification:);

        [defaultCenter addObserver:self
                          selector:notificationSelector
                              name:IMUTLibClockDidStartNotification
                            object:nil];

        [defaultCenter addObserver:self
                          selector:notificationSelector
                              name:IMUTLibClockDidStopNotification
                            object:nil];

        _dispatch_queue = makeDispatchQueue(@"module-registry", DISPATCH_QUEUE_SERIAL, DISPATCH_QUEUE_PRIORITY_DEFAULT);
    }

    return self;
}

- (NSObject <IMUTLibSessionTimer> *)timer {
    // As long as initialization of the IMUT library is not done, we don't know the best time source.
    if (!_frozen) {
        return nil;
    }

    if (!_timer) {
        _timer = [_sessionTimerClass new];
    }

    return _timer;
}

- (NSSet *)moduleInstancesWithType:(NSUInteger)moduleType {
    NSSet *set = _enabledInstancesByType[[NSNumber numberWithLong:moduleType]];

    return set ?: [NSSet set];
}

- (IMUTLibModule *)moduleInstanceWithName:(NSString *)name {
    return _enabledInstancesByName[name];
}

- (void)enableModulesWithConfigs:(NSDictionary *)moduleConfigs {
    [moduleConfigs enumerateKeysAndObjectsUsingBlock:^(NSString *moduleName, NSDictionary *moduleConfig, BOOL *stop) {
        if (![self enableModuleWithName:moduleName config:moduleConfig]) {
            @throw [NSException exceptionWithName:IMUTLibFailedToEnableModuleException
                                           reason:[NSString stringWithFormat:@"IMUT was unable to initialize module \"%@\".",
                                                                             moduleName]
                                         userInfo:nil];
        }
    }];

    // Once the modules have been enabled, freeze the registry
    [self freeze];
}

- (void)registerModuleWithClass:(Class)moduleClass {
    @synchronized (self) {
        NSAssert(!_frozen, @"Cannot add module with class \"%@\" as the module registry is already frozen.", NSStringFromClass(moduleClass));
        NSAssert(classIsSubclassOfClass(moduleClass, [IMUTLibModule class]), @"The module identified by class \"%@\" is not a subclass of \"IMUTLibModule\".", NSStringFromClass(moduleClass));

        NSString *moduleName = [moduleClass performSelector:@selector(moduleName)];
        [(NSMutableDictionary *) _registeredModuleClasses setObject:moduleClass forKey:moduleName];
    }
}

- (void)registerSessionTimerWithClass:(Class)sessionTimerClass {
    @synchronized (self) {
        NSAssert(classConformsToProtocol(@ protocol(IMUTLibSessionTimer), sessionTimerClass), @"The class is conform with the <IMUTLibSessionTimer> protocol.");

        if ([(Class <IMUTLibSessionTimer>) sessionTimerClass preference] > [(Class <IMUTLibSessionTimer>) _sessionTimerClass preference]) {
            // Registered time source is better than the previous one
            _sessionTimerClass = sessionTimerClass;
        }
    }
}

- (void)notifyModulesWithNotification:(NSNotification *)notification {
    // Upon any notification the registry must be frozen
    if (!_frozen) {
        [self freeze];
    }

    __weak NSDictionary *weakModuleInstances = _enabledInstancesByName;
    dispatch_async(_dispatch_queue, ^{
        for (NSString *moduleName in weakModuleInstances) {
            if (notification.name == IMUTLibClockDidStartNotification) {
                [weakModuleInstances[moduleName] startWithSession:notification.object];
            } else {
                [weakModuleInstances[moduleName] stopWithSession:notification.object];
            }
        }
    });
}

- (NSDictionary *)configForModuleWithName:(NSString *)moduleName {
    if (_frozen) {
        return _moduleConfigs[moduleName];
    }

    return nil;
}

#pragma mark Private

- (BOOL)enableModuleWithName:(NSString *)moduleName config:(NSDictionary *)moduleConfig {
    // Already enabled?
    if ([_enabledInstancesByName objectForKey:moduleName]) {
        return YES;
    }

    Class moduleClass = [_registeredModuleClasses objectForKey:moduleName];

    // Collect module config
    NSMutableDictionary *tempConfig = [[moduleClass defaultConfig] mutableCopy];
    if (!tempConfig) {
        tempConfig = [NSMutableDictionary dictionary];
    }
    [tempConfig addEntriesFromDictionary:moduleConfig];
    moduleConfig = [tempConfig copy];
    ((NSMutableDictionary *) _moduleConfigs)[moduleName] = moduleConfig;

    // Create module instance
    IMUTLibModule *moduleInstance = [[moduleClass alloc] initWithConfig:moduleConfig];

    if (moduleInstance) {
        // Remember we enabled this module
        [(NSMutableSet *) _enabledModulesByName addObject:moduleName];

        // Retain the instance
        [(NSMutableDictionary *) _enabledInstancesByName setObject:moduleInstance forKey:moduleName];

        // Classify by module type(s)
        BOOL hasValidModuleType = NO;
        IMUTLibModuleType moduleType = [moduleClass moduleType];
        if (moduleType & IMUTLibModuleTypeEvented) {
            hasValidModuleType = YES;
            [_enabledInstancesByType[@(IMUTLibModuleTypeEvented)] addObject:moduleInstance];
        }
        if (moduleType & IMUTLibModuleTypeStream) {
            hasValidModuleType = YES;
            [_enabledInstancesByType[@(IMUTLibModuleTypeStream)] addObject:moduleInstance];
        }

        // Check for valid module type
        NSAssert(hasValidModuleType, @"The module \"%@\" does not designate a valid module type.", moduleName);

        // Handle source event producers, which must also be aggregators
        if (moduleType & IMUTLibModuleTypeEvented) {
            NSAssert([moduleInstance respondsToSelector:@
                selector(registerEventAggregatorBlocksInRegistry:)],
                    @"The module \"%@\" does not implement the IMUTLibEventAggregator protocol.",
                    moduleName);

            if ([moduleInstance isMemberOfClass:[IMUTLibPollingModule class]]) {
                [(NSMutableSet *) _pollingModuleInstances addObject:moduleInstance];
            }
        }

        // Check if the module has a custom time source
        Class <IMUTLibSessionTimer> sessionTimerClass = [moduleClass sessionTimerClass];
        if (sessionTimerClass) {
            [self registerSessionTimerWithClass:sessionTimerClass];
        }

        IMUTLogMain(@"Using module \"%@\"", moduleName);

        return YES;
    }

    IMUTLogMain(@"Unable to enable module \"%@\".", moduleName);

    return NO;
}

- (void)freeze {
    @synchronized (self) {
        if (!_frozen) {
            [IMUTLibUtil postNotificationName:IMUTLibModuleRegistryWillFreezeNotification
                                       object:self
                                 onMainThread:NO
                                waitUntilDone:YES];

            _frozen = YES;

            _enabledModulesByName = [_enabledModulesByName copy];
            _registeredModuleClasses = [_registeredModuleClasses copy];
            _enabledInstancesByName = [_enabledInstancesByName copy];
            _pollingModuleInstances = [_pollingModuleInstances copy];
            _moduleConfigs = [_moduleConfigs copy];

            [IMUTLibUtil postNotificationName:IMUTLibModuleRegistryDidFreezeNotification
                                       object:self
                                 onMainThread:NO
                                waitUntilDone:YES];
        }
    }
}

@end
