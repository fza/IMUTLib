#import "IMUTLibMain.h"
#import "IMUTLibMain+Internal.h"
#import "IMUTLibConstants.h"

// Still a prototype, thus major version is 0
unsigned int const IMUT_MAJOR_VERSION = 0;
unsigned int const IMUT_MINOR_VERSION = 1;
unsigned int const IMUT_PATCH_VERSION = 0;

static IMUTLibMain *sharedInstance;

// Private interface
@interface IMUTLibMain ()

+ (instancetype)alloc __attribute__((unavailable("alloc is not available, use [IMUTLibMain imut] instead")));

+ (instancetype)new __attribute__((unavailable("new is not available, use [IMUTLibMain imut] instead")));

- (instancetype)init __attribute__((unavailable("init is not available, use [IMUTLibMain imut] instead")));

- (instancetype)initWithConfigFromPlistFile:(NSString *)plistFileName;

@end

@implementation IMUTLibMain

# pragma mark Public API

+ (NSString *)imutVersion {
    static NSString *imutVersion;

    if (!imutVersion) {
        imutVersion = [NSString stringWithFormat:@"%d.%d.%d",
                                                 IMUT_MAJOR_VERSION,
                                                 IMUT_MINOR_VERSION,
                                                 IMUT_PATCH_VERSION];
    }

    return imutVersion;
}

+ (void)setup {
    [self setupWithConfigFromPlistFile:IMUTLibDefaultPlistFilename];
}

+ (void)setupWithConfigFromPlistFile:(NSString *)configFile {
    NSAssert(!sharedInstance, @"Attempt to setup IMUT a second time.");

    static dispatch_once_t once;
    dispatch_once(&once, ^{
        IMUTLogMain(@"Version %@", [IMUTLibMain imutVersion]);

        sharedInstance = [(IMUTLibMain *) [super alloc] initWithConfigFromPlistFile:configFile];

        // Autostart?
        if ([[sharedInstance.config valueForConfigKey:kIMUTLibConfigAutostart default:numNO] boolValue]) {
            [sharedInstance start];
        }
    });
}

+ (instancetype)imut {
    if (!sharedInstance) {
        [[self class] setup];
    }

    return sharedInstance;
}

+ (BOOL)registerModuleWithClass:(Class)moduleClass {
    return [[IMUTLibModuleRegistry sharedInstance] registerModuleWithClass:moduleClass];
}

- (void)start {
        [self doStart];
}

#pragma mark Private

- (instancetype)initWithConfigFromPlistFile:(NSString *)plistFileName {
    if (sharedInstance) {
        return sharedInstance;
    }

    if (!plistFileName) {
        @throw [NSException exceptionWithName:IMUTLibInitWithoutConfigrationException
                                       reason:@"Attempt to init IMUT without configuration."
                                     userInfo:nil];
    }

    if (self = [super init]) {
        if (![self readConfigFromPlistFileWithName:plistFileName]) {
            @throw [NSException exceptionWithName:IMUTLibFailedToReadConfigurationException
                                           reason:[NSString stringWithFormat:@"IMUT was unable to read confguration file \"%@\"",
                                                                             plistFileName]
                                         userInfo:nil];
        }
    }

    return self;
}

@end
