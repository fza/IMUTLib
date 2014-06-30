#import "IMUTLibConfig.h"
#import "IMUTLibConstants.h"
#import "Macros.h"

@implementation IMUTLibConfig {
    NSDictionary *_config;
    NSSet *_enabledModuleNames;
}

DESIGNATED_INIT

+ (instancetype)configFromPlistFileWithName:(NSString *)plistFileName {
    return [[self alloc] initWithPlistFile:plistFileName];
}

- (instancetype)initWithPlistFile:(NSString *)plistFileName {
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:[plistFileName stringByDeletingPathExtension]
                                                          ofType:@"plist"];
    NSDictionary *configDict = [NSDictionary dictionaryWithContentsOfFile:plistPath];

    if (!configDict) {
        return nil;
    }

    return [self initWithConfigDict:configDict];
}

- (instancetype)initWithConfigDict:(NSDictionary *)configDict {
    if (self = [super init]) {
        _config = configDict;
    }

    return self;
}

- (NSDictionary *)moduleConfigs {
    id rawModuleConfigs = [_config objectForKey:@"modules"];

    if (!rawModuleConfigs || ![rawModuleConfigs isKindOfClass:[NSDictionary class]]) {
        return @{};
    }

    NSMutableSet *enabledModuleNames = [NSMutableSet set];
    NSMutableDictionary *moduleConfigs = [NSMutableDictionary dictionary];
    [rawModuleConfigs enumerateKeysAndObjectsUsingBlock:^void(id key, id obj, BOOL *stop) {
        // Should never happen, but better test it
        if (![key isKindOfClass:[NSString class]]) {
            return;
        }

        if ([obj isEqual:numYES]) {
            moduleConfigs[key] = @{};
            [enabledModuleNames addObject:key];
        } else if ([obj isKindOfClass:objc_getClass("NSDictionary")]) {
            moduleConfigs[key] = obj;
            [enabledModuleNames addObject:key];
        }
    }];

    _enabledModuleNames = [NSSet setWithSet:enabledModuleNames];

    return moduleConfigs;
}

- (NSSet *)enabledModuleNames {
    return _enabledModuleNames;
}

- (id)valueForConfigKey:(NSString *)key default:(id)defaultValue {
    if ([key isEqualToString:@"modules"]) {
        return defaultValue;
    }

    id value = [_config objectForKey:key];

    if (!value) {
        value = defaultValue;
    }

    return value;
}

@end
