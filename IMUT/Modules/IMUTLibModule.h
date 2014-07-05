#import <Foundation/Foundation.h>

#import "IMUTLibSessionTimer.h"
#import "IMUTLibSession.h"
#import "IMUTLibEventAggregatorRegistry.h"
#import "IMUTLibSourceEventCollection.h"
#import "IMUTLibMain.h"

// Module types
typedef NS_ENUM(NSUInteger, IMUTLibModuleType) {
    IMUTLibModuleTypeStream = 1,
    IMUTLibModuleTypeEvented = 2
};

// An abstract module class that eases implementation of IMUT modules.
// IMUT always initializes modules by calling `initWithConfig:`!
@interface IMUTLibModule : NSObject {
    NSDictionary *_config;
}

#pragma mark Methods subclasses must override

// The unique module name
+ (NSString *)moduleName;

// The module initializer. If you return nil, the module will be ignored even
// if it's enabled in the configuration. // Returns the object produced by
// `[super init]` by default. Modules that override this method must call
// `[super initWithConfig:config]`!
- (id)initWithConfig:(NSDictionary *)config;

#pragma mark Methods with default implementation or default NOOPs

// The module type
// Returns `IMUTLibModuleTypeEvented` by default
+ (IMUTLibModuleType)moduleType;

// If this module has a custom time source, it shall return it's class here
+ (Class <IMUTLibSessionTimer>)sessionTimerClass;

// The default configuration dictionary, need not be implemented if there is no
// configuration. Returns nil by default.
+ (NSDictionary *)defaultConfig;

// If a module can produces initial events, it should return those here.
// Need not be implemented.
- (NSSet *)eventsWithInitialState;

// If a module wants to enqueue final events, it should do so here.
- (NSSet *)eventsWithFinalState;

// Default entity type
- (IMUTLibPersistableEntityType)defaultEntityType;

// Start callback, This is to inform the module that a session and time source is
// guaranteed to exist. As a module is allowed to produce events at any application
// state it need not implements this method.
- (void)startWithSession:(IMUTLibSession *)session;

// Stop callback. This is called when the session timer did stop and the session
// is about to be invalidated.
- (void)stopWithSession:(IMUTLibSession *)session;

// This method is invoked once by the IMUT runtime to let the receiver register its
// aggregator blocks. However, modules that enqueue source events >>MUST<< implement
// this module.
- (void)registerEventAggregatorBlocksInRegistry:(IMUTLibEventAggregatorRegistry *)registry;

@end
