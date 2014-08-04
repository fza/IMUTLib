@interface IMUTLibMain : NSObject

// IMUT version
+ (NSString *)imutVersion;

// Convenient setup method, implicitly trying to read the `IMUT.plist` file
+ (void)setup;

// Setup method to use when the `IMUT.plist` file is named something else
+ (void)setupWithConfigFromPlistFile:(NSString *)configFile;

// The shared `IMUTLibMain` instance
+ (instancetype)imut;

// Register a new module by its class
+ (void)registerModuleWithClass:(Class)moduleClass;

// Start IMUT manually, if the `autostart` setting is `NO` in the `IMUT.plist` file
- (void)start;

@end
