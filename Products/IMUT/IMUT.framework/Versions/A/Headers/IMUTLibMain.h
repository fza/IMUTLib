#import <Foundation/Foundation.h>

#if !__has_feature(objc_arc)
    #error IMUT is ARC only. Either turn on ARC or use -fobjc-arc flag for the `IMUTLibMain` framework
#endif

// The IMUT version constants
extern unsigned long const IMUT_MAJOR_VERSION;
extern unsigned long const IMUT_MINOR_VERSION;
extern unsigned long const IMUT_PATCH_VERSION;
extern NSString *const IMUT_VERSION_STRING;

@interface IMUTLibMain : NSObject

// A flag indicating if IMUT has started
@property(nonatomic, readonly) BOOL started;

// Do not use these
+ (instancetype)alloc __attribute__((unavailable("alloc not available, use [IMUTLibMain imut] instead")));

+ (instancetype)new __attribute__((unavailable("new not available, use [IMUTLibMain imut] instead")));

- (instancetype)init __attribute__((unavailable("init not available, use [IMUTLibMain imut] instead")));

// Convenient setup method, implicitly trying to read the `IMUT.plist` file
+ (void)setup;

// Setup method to use when the `IMUT.plist` file is named something else
+ (void)setupWithConfigFromPlistFile:(NSString *)configFile;

// The shared `IMUTLibMain` instance
+ (instancetype)imut;

// Register a new module by its metaclass. Note that the module must implement
// the `IMUTLibModule` protocol. Returns true if it was registered successfully,
// false otherwise. Must be called before IMUT is started, thus the `autostart`
// configuration must be off and [[IMUT shared] start] must be called manually
// when the app initializes, after custom modules have been registered. Note that
// any custom modules need to be configured in the plist config file in order to
// be enabled by IMUT.
- (BOOL)registerModuleWithClass:(Class)moduleClass;

// Start IMUT manually, if the `autostart` setting is `NO` in the `IMUT.plist` file
- (void)start;

@end
