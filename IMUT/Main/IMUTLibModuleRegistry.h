#import <Foundation/Foundation.h>

#import "Macros.h"
#import "IMUTLibModule.h"
#import "IMUTLibSessionTimer.h"

// The module container used to access registered modules and to register additional modules.
// Use `[IMUTLibMain imut].moduleRegistry` to get access to the shared instance.
@interface IMUTLibModuleRegistry : NSObject

// All enabled modules by name
@property(nonatomic, readonly, retain) NSSet *enabledModulesByName;

// All module instances which request polling
@property(nonatomic, readonly, retain) NSSet *pollingModuleInstances;

// Wether this registry is frozen
@property(nonatomic, readonly, assign) BOOL frozen;

// Get the one module which implements the IMUTLibSessionTimer protocol and has the highest preference
@property(nonatomic, readonly, retain) NSObject <IMUTLibSessionTimer> *timer;

SINGLETON_INTERFACE

// Returns enabled modules by type
- (NSSet *)moduleInstancesWithType:(NSUInteger)moduleType;

// Return a specific module
- (IMUTLibModule *)moduleInstanceWithName:(NSString *)name;

// Enables all modules
- (void)enableModulesWithConfigs:(NSDictionary *)moduleConfigs;

// Register a new module by its class
- (void)registerModuleWithClass:(Class)moduleClass;

// Register a new time source by its class
- (void)registerSessionTimerWithClass:(Class)sessionTimerClass;

// Notify modules. Ensures that modules are called in order of the dependency chain.
- (void)notifyModulesWithNotification:(NSNotification *)notification;

// Get the configuration for a module. Only available when the registry is frozen
- (NSDictionary *)configForModuleWithName:(NSString *)moduleName;

@end
