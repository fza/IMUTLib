#import <Foundation/Foundation.h>
#import "IMUTLibModule.h"

// An abstract module class that eases implementation of IMUT modules.
// IMUT always initializes modules by calling `initWithConfig:`!
@interface IMUTLibAbstractModule : NSObject <IMUTLibModule> {
    NSDictionary *_config;
}

#pragma mark Methods subclasses must override

// Must be implemented by subclass!
+ (NSString *)moduleName;

#pragma mark Methods with default implementation

// Returns the object produced by `[super init]` by default
// Modules that override this method must call `[super initWithConfig:config]`!
- (id)initWithConfig:(NSDictionary *)config;

// Returns `IMUTLibModuleTypeEvented` by default
+ (IMUTLibModuleType)moduleType;

@end
