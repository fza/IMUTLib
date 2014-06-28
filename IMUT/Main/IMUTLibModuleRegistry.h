#import <Foundation/Foundation.h>
#import "IMUTLibTimeSource.h"
#import "IMUTLibModule.h"
#import "Macros.h"

// The module container used to access registered modules and to register additional modules.
// Use `[IMUTLibMain imut].moduleRegistry` to get access to the shared instance.
@interface IMUTLibModuleRegistry : NSObject

// Wether this registry is frozen
@property(atomic, readonly, assign) BOOL frozen;

// YES if there is at least one enabled recorder module, may give an invalid `NO` result if IMUT
// did not fully initialize yet.
@property(nonatomic, readonly, assign) BOOL haveMediaStream;

// Get the one module which implements the IMUTLibTimeSource protocol and has the highest preference
@property(nonatomic, readonly, retain) NSObject <IMUTLibTimeSource> *bestTimeSource;

SINGLETON_INTERFACE

// Returns enabled modules by type
- (NSSet *)moduleInstancesWithType:(NSUInteger)moduleType;

// Return a specific module
- (id <IMUTLibModule>)moduleInstanceWithName:(NSString *)name;

// Enables all modules
- (void)enableModulesWithConfigs:(NSDictionary *)moduleConfigs;

// Register a new module by its metaclass
- (BOOL)registerModuleWithClass:(Class)moduleClass;

// Notify modules. Ensures that modules are called in order of the dependency chain.
- (void)notifyModulesWithNotification:(NSNotification *)notification;

// Get the configuration for a module, only available when the registry is frozen
- (NSDictionary *)configForModuleWithName:(NSString *)moduleName;

@end
