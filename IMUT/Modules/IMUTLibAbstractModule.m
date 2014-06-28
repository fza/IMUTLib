#import "IMUTLibAbstractModule.h"
#import "Macros.h"

@implementation IMUTLibAbstractModule

ABSTRACT_CLASS("IMUTLibAbstractModule")

+ (NSString *)moduleName {
    MethodNotImplementedException(@"moduleName");
}

+ (IMUTLibModuleType)moduleType {
    return IMUTLibModuleTypeEvented;
}

- (id)initWithConfig:(NSDictionary *)config {
    if (self = [super init]) {
        _config = config;
    }

    return self;
}

- (NSDictionary *)config {
    return _config;
}

@end
