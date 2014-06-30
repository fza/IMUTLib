#import <Foundation/Foundation.h>
#import "IMUTLibSourceEvent.h"
#import "IMUTLibSession.h"

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
// The default configuration dictionary, need not be implemented if there is no
// configuration.
+ (NSDictionary *)defaultConfig;

// If a module can produces initial events, it should return those here.
// Need not be implemented.
- (NSSet *)eventsWithCurrentState;

// Start callback, This is to inform the module that a session and time source is
// guaranteed to exist. As a module is allowed to produce events at any application
// state it need not implements this method.
- (void)startWithSession:(IMUTLibSession *)session;

// Pause callback. This is called when the time source did stop and the session
// is about to be invalidated.
- (void)pauseWithSession:(IMUTLibSession *)session;

@end
