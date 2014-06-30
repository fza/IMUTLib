#import <Foundation/Foundation.h>
#import "IMUTLibMain.h"
#import "IMUTLibModuleRegistry.h"
#import "IMUTLibConfig.h"
#import "IMUTLibEventSynchronizer.h"
#import "IMUTLibSession.h"

@interface IMUTLibMain (Internal)

// The current session. It is ensured that this is never nil.
@property(nonatomic, readonly, retain) IMUTLibSession *session;

// The configuration
@property(nonatomic, readonly, retain) IMUTLibConfig *config;

- (BOOL)readConfigFromPlistFileWithName:(NSString *)plistFileName;

- (BOOL)isTerminated;

- (void)doStart;

@end
