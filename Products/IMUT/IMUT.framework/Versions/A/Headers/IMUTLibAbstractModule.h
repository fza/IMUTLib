#import <Foundation/Foundation.h>
#import "IMUTLibModule.h"

// An abstract module class that eases implementation of IMUT modules.
// IMUT always initializes modules by calling `initWithConfig:`!
@interface IMUTLibAbstractModule : NSObject <IMUTLibModule>

#pragma mark Methods to be overriden by subclass

// Must be implemented by subclass!
+ (NSString *)moduleName;

#pragma mark Methods with default implementation

// Returns the object produced by `[super init]` by default
- (id)initWithConfig:(NSDictionary *)config;

// Returns `IMUTLibModuleTypeDataEvents` by default
+ (IMUTLibModuleType)moduleType;

@end
