#import <Foundation/Foundation.h>

#import "IMUTLibMain.h"
#import "IMUTLibConfig.h"
#import "IMUTLibSession.h"

@interface IMUTLibMain (Internal)

// The current session. It is ensured that this is never nil.
@property(nonatomic, readonly, retain) IMUTLibSession *session;

// The configuration
@property(nonatomic, readonly, retain) IMUTLibConfig *config;

- (BOOL)readConfigFromPlistFileWithName:(NSString *)plistFileName;

- (BOOL)isPaused;

- (BOOL)isTerminated;

- (void)doStart;

@end
