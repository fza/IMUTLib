#import "IMUTLibModule.h"

@implementation IMUTLibModule

ABSTRACT_CLASS("IMUTLibModule")

+ (NSString *)moduleName {
    MethodNotImplementedException(@"moduleName");
}

- (id)initWithConfig:(NSDictionary *)config {
    if (self = [super init]) {
        _config = config;
    }

    return self;
}

+ (IMUTLibModuleType)moduleType {
    return IMUTLibModuleTypeEvented;
}

+ (Class <IMUTLibSessionTimer>)sessionTimerClass {
    return nil;
}

- (NSDictionary *)config {
    return _config;
}

+ (NSDictionary *)defaultConfig {
    return nil;
}

- (NSSet *)eventsWithInitialState {
    return nil;
}

- (NSSet *)eventsWithFinalState {
    return nil;
}

- (IMUTLibPersistableEntityType)defaultEntityType {
    return IMUTLibPersistableEntityTypeAbsolute;
}

- (void)startWithSession:(IMUTLibSession *)session {
}

- (void)stopWithSession:(IMUTLibSession *)session {
}

- (void)registerEventAggregatorBlocksInRegistry:(IMUTLibEventAggregatorRegistry *)registry {
}

- (Class <IMUTLibSessionTimer>)sessionTimerClass {
    return nil;
}

@end
