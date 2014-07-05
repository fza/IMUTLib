#import <libkern/OSAtomic.h>
#import <UIKit/UIKit.h>

#import "IMUTLibMain+Internal.h"
#import "IMUTLibFunctions.h"
#import "IMUTLibModuleRegistry.h"
#import "IMUTLibUtil.h"
#import "IMUTLibConstants.h"
#import "IMUTLibEventSynchronizer.h"
#import "IMUTLibSourceEventCollection.h"
#import "IMUTLibEventAggregatorRegistry.h"
#import "IMUTLibFileManager.h"
#import "IMUTLibTimer.h"

#define CHECK_SESSION_STOP_INTERVAL 0.5
#define CHECK_SESSION_STOP_MAX_TIMES 10 // wait 5 seconds until crash

static BOOL started;

static OSSpinLock notificationLock;
static OSSpinLock sessionLock;
static dispatch_queue_t dispatchQueue;

@interface IMUTLibMain (InternalPrivate)

- (void)enableModules;

- (void)observeNotifications;

- (void)applicationWillResignActive:(NSNotification *)notification;

- (void)applicationDidBecomeActive:(NSNotification *)notification;

- (void)applicationWillTerminate:(NSNotification *)notification;

- (void)createNewSessionWithCompletionBlock:(void (^)(void))completionBlock;

- (void)stopCurrentSessionWithCompletionBlock:(void (^)(void))completionBlock;

- (void)setPaused:(BOOL)flag;

@end

#pragma mark Internal private methods

@implementation IMUTLibMain (InternalPrivate)

+ (void)load {
    notificationLock = OS_SPINLOCK_INIT;
    sessionLock = OS_SPINLOCK_INIT;
    dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
}

- (void)enableModules {
    [[IMUTLibModuleRegistry sharedInstance] enableModulesWithConfigs:[self.config moduleConfigs]];
}

- (void)observeNotifications {
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];

    [defaultCenter addObserver:self
                      selector:@selector(applicationWillResignActive:)
                          name:UIApplicationWillResignActiveNotification
                        object:nil];

    [defaultCenter addObserver:self
                      selector:@selector(applicationDidBecomeActive:)
                          name:UIApplicationDidBecomeActiveNotification
                        object:nil];

    [defaultCenter addObserver:self
                      selector:@selector(applicationWillTerminate:)
                          name:UIApplicationWillTerminateNotification
                        object:nil];
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    dispatch_async(dispatchQueue, ^{
        OSSpinLockLock(&notificationLock);
        if (![self isPaused]) {
            [self setPaused:YES];

            [IMUTLibUtil postNotificationName:IMUTLibWillPauseNotification
                                       object:self
                                 onMainThread:NO
                                waitUntilDone:YES];

            [self stopCurrentSessionWithCompletionBlock:nil];
        }

        OSSpinLockUnlock(&notificationLock);
    });
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    dispatch_async(dispatchQueue, ^{
        OSSpinLockLock(&notificationLock);

        if ([self isPaused]) {
            [self setPaused:NO];

            // There may be events left from the last session, wipe them out
            [[IMUTLibEventSynchronizer sharedInstance] clearCache];

            // Create new session and start it directly
            [self createNewSessionWithCompletionBlock:^{
                [self.session startWithCompletionBlock:^(BOOL started){
                    [IMUTLibUtil postNotificationName:IMUTLibDidResumeNotification
                                               object:self
                                         onMainThread:NO
                                        waitUntilDone:YES];
                }];
            }];
        }

        OSSpinLockUnlock(&notificationLock);
    });
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    dispatch_async(dispatchQueue, ^{
        objc_setAssociatedObject(self, @selector(isTerminated), numYES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

        [IMUTLibUtil postNotificationName:IMUTLibWillTerminateNotification
                                   object:self
                             onMainThread:NO
                            waitUntilDone:YES];

        [self stopCurrentSessionWithCompletionBlock:nil];
    });
}

- (void)createNewSessionWithCompletionBlock:(void (^)(void))completionBlock {
    __weak id weakSelf = self;
    void (^createNewSessionBlock)(void) = ^{
        // Create new session
        IMUTLibSession *newSession = [IMUTLibSession sessionWithTimer:[IMUTLibModuleRegistry sharedInstance].timer];

        IMUTLogMain(@"Session ID: %@", newSession.sessionId);

        // Replace session reference
        objc_setAssociatedObject(weakSelf, @selector(session), newSession, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

        // Post global notification
        [IMUTLibUtil postNotificationName:IMUTLibDidCreateSessionNotification
                                   object:weakSelf
                             onMainThread:NO
                            waitUntilDone:YES];

        if (completionBlock) {
            completionBlock();
        }
    };

    if (!OSSpinLockTry(&sessionLock)) {
        [self stopCurrentSessionWithCompletionBlock:createNewSessionBlock];
    } else {
        createNewSessionBlock();
    }
}

- (void)stopCurrentSessionWithCompletionBlock:(void (^)(void))completionBlock {
    // If we can't aquire the lock, this means we have a current session to be stopped
    if (!OSSpinLockTry(&sessionLock)) {
        IMUTLibSession *session = self.session;
        if (session && !session.invalid) {
            // Set invalid flag. All those objects which retained the session object
            // It is the responsibility of all those objects which retained the session
            // object to check for invalidity.

            [session stopWithCompletionBlock:^(BOOL stopped){
                IMUTLogMain(@"Recorded %.2f seconds", self.session.duration);

                // Post global notification
                [IMUTLibUtil postNotificationName:IMUTLibDidInvalidateSessionNotification
                                           object:self
                                     onMainThread:NO
                                    waitUntilDone:YES];

                if (completionBlock) {
                    completionBlock();
                }

                OSSpinLockUnlock(&sessionLock);
            }];
        } else {
            OSSpinLockUnlock(&sessionLock);
        }
    }
}

- (void)setPaused:(BOOL)flag {
    objc_setAssociatedObject(self, @selector(isPaused), oBool(flag), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark Internal methods

@implementation IMUTLibMain (Internal)

@dynamic session;
@dynamic config;

- (BOOL)readConfigFromPlistFileWithName:(NSString *)plistFileName {
    IMUTLibConfig *config = [IMUTLibConfig configFromPlistFileWithName:plistFileName];

    if (config) {
        objc_setAssociatedObject(self, @selector(config), config, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    return config != nil;
}

- (IMUTLibConfig *)config {
    return objc_getAssociatedObject(self, @selector(config));
}

- (IMUTLibSession *)session {
    IMUTLibSession *session;

    // Only if it's locked down we can be sure that there is a session
    if (!OSSpinLockTry(&sessionLock)) {
        session = objc_getAssociatedObject(self, @selector(session));
    }

    return session;
}

- (BOOL)isPaused {
    NSNumber *paused = objc_getAssociatedObject(self, @selector(isPaused));

    return paused ? [paused boolValue] : NO;
}

- (BOOL)isTerminated {
    return objc_getAssociatedObject(self, @selector(isTerminated)) != nil;
}

- (void)doStart {
    // Aquire lock during startup
    NSAssert(OSSpinLockTry(&notificationLock), @"Unable to aquire startup lock.");

    [self setPaused:NO];

    // Initial state
    started = NO;

    // Listen for runtime notifications as early as possible
    [self observeNotifications];

    static dispatch_once_t startOnceToken;
    dispatch_once(&startOnceToken, ^{
        // Invoke start procedure in a dedicated thread
        dispatch_async(dispatchQueue, ^{
            // Make sure all core objects did initialize
            [IMUTLibSourceEventCollection sharedInstance];
            [IMUTLibEventAggregatorRegistry sharedInstance];
            [IMUTLibModuleRegistry sharedInstance];

            // Set the sync time interval
            NSTimeInterval syncTimeInterval = [(NSNumber *) [self.config valueForConfigKey:kIMUTLibConfigSynchronizationTimeInterval
                                                                                   default:@0.25] doubleValue];
            [IMUTLibEventSynchronizer sharedInstance].syncTimeInterval = syncTimeInterval;

            // Remove old, unfinished files
            if (![(NSNumber *) [self.config valueForConfigKey:kIMUTLibConfigKeepUnfinishedFiles
                                                      default:numNO] boolValue]) {
                [IMUTLibFileManager removeTemporaryFiles];
            }

#if DEBUG
            // Remove old files by date (now-30 minutes)
            [IMUTLibFileManager removeAllFilesCreatedBeforeDate:[[NSDate date] dateByAddingTimeInterval:(-30.0 * 60)]];
#endif

            // Enable modules
            [self enableModules];

            // Create the first session
            __weak IMUTLibMain *weakSelf = self;
            [self createNewSessionWithCompletionBlock:^{
                // Tell all observers that we are about to start.
                // This will, however, not inform modules to start as they are notified after
                // the session started and the time source started ticking. This notification
                // is posted by the module registry by directly calling the particular module
                // method.
                [IMUTLibUtil postNotificationName:IMUTLibWillStartNotification
                                           object:weakSelf
                                     onMainThread:NO
                                    waitUntilDone:YES];

                // Start the session
                // TODO Handle the case when the session did not start
                [weakSelf.session startWithCompletionBlock:^(BOOL sessionStarted){
                    // We are ready
                    started = YES;

                    // Release the lock
                    OSSpinLockUnlock(&notificationLock);
                }];
            }];
        });
    });
}

@end
