#import <Foundation/Foundation.h>
#import "IMUTLibSourceEvent.h"

typedef NS_ENUM(NSUInteger, IMUTLibModuleType) {
    IMUTLibModuleTypeStream = 1,
    IMUTLibModuleTypeEvented = 2,
    IMUTLibModuleTypeAll = 4
};

@protocol IMUTLibModule

// The unique module name
+ (NSString *)moduleName;

// The module type
+ (IMUTLibModuleType)moduleType;

// The module initializer. If you return nil, the module will be ignored even
// if it's enabled in the configuration.
- (id)initWithConfig:(NSDictionary *)config;

@optional
// The default configuration dictionary
+ (NSDictionary *)defaultConfig;

// If a module can produce an initial event, it should return it here
- (NSSet *)eventsWithCurrentState;

// Start callback
- (void)start;

// Pause callback
- (void)pause;

// Resume callback
- (void)resume;

// Terminate callback
- (void)terminate;

@end
