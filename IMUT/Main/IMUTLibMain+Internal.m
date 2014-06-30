#import <UIKit/UIKit.h>
#import <libkern/OSAtomic.h>
#import "IMUTLibMain+Internal.h"
#import "IMUTLibConstants.h"
#import "IMUTLibFileManager.h"
#import "IMUTLibSourceEventQueue.h"
#import "IMUTLibUtil.h"
#import "IMUTLibEventAggregatorRegistry.h"
#import "IMUTLibFunctions.h"

static BOOL paused;
static BOOL started;
static OSSpinLock notificationLock;
static OSSpinLock sessionLock;
static dispatch_queue_t mainDispatchQueue;

@interface IMUTLibMain (InternalPrivate)

- (void)enableModules;

- (void)observeNotifications;

- (void)applicationWillResignActive:(NSNotification *)notification;

- (void)applicationDidBecomeActive:(NSNotification *)notification;

- (void)applicationWillTerminate:(NSNotification *)notification;

- (void)createNewSession;

- (void)invalidateCurrentSession;

@end

#pragma mark Internal private methods

@implementation IMUTLibMain (InternalPrivate)

+ (void)load {
    notificationLock = OS_SPINLOCK_INIT;
    sessionLock = OS_SPINLOCK_INIT;
    mainDispatchQueue = mainImutDispatchQueue(DISPATCH_QUEUE_PRIORITY_HIGH);
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
    OSSpinLockLock(&notificationLock);

    if (!paused && ![self isTerminated]) {
        dispatch_async(mainDispatchQueue, ^{
            paused = YES;

            [IMUTLibUtil postNotificationName:IMUTLibWillPauseNotification
                                       object:self
                                 onMainThread:NO
                                waitUntilDone:YES];

            [self invalidateCurrentSession];

            OSSpinLockUnlock(&notificationLock);
        });
    } else {
        OSSpinLockUnlock(&notificationLock);
    }
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    OSSpinLockLock(&notificationLock);

    if (paused && ![self isTerminated]) {
        dispatch_async(mainDispatchQueue, ^{
            paused = NO;

            [[IMUTLibEventSynchronizer sharedInstance] clearCache];

            [self createNewSession];

            [IMUTLibUtil postNotificationName:IMUTLibDidResumeNotification
                                       object:self
                                 onMainThread:NO
                                waitUntilDone:YES];

            OSSpinLockUnlock(&notificationLock);
        });
    } else {
        OSSpinLockUnlock(&notificationLock);
    }
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    OSSpinLockLock(&notificationLock);

    dispatch_async(mainDispatchQueue, ^{
        objc_setAssociatedObject(self, @selector(isTerminated), numYES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

        [IMUTLibUtil postNotificationName:IMUTLibWillTerminateNotification
                                   object:self
                             onMainThread:NO
                            waitUntilDone:YES];

        [self invalidateCurrentSession];

        // DO NOT RELEASE THE NOTIFICATION LOCK FOR SAFETY PURPOSES
        // IT MUST NOT BE POSSIBLE TO RE-ENTER PROCESSING NOW!
        //
        // Note that it may be possible that some internal IMUT threads are still
        // running, they will finish soon from now.
    });
}

- (void)createNewSession {
    [self invalidateCurrentSession];

    // Create new session
    IMUTLibSession *newSession = [IMUTLibSession sessionWithTimeSource:[IMUTLibModuleRegistry sharedInstance].bestTimeSource];

    IMUTLogMain(@"Session ID: %@", newSession.sessionId);

    // Replace session reference
    OSSpinLockLock(&sessionLock);
    objc_setAssociatedObject(self, @selector(session), newSession, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    OSSpinLockUnlock(&sessionLock);

    // Post global notification
    [IMUTLibUtil postNotificationName:IMUTLibDidCreateSessionNotification
                               object:self
                         onMainThread:NO
                        waitUntilDone:YES];
}

- (void)invalidateCurrentSession {
    if (self.session) {
        // Set invalid flag. All those objects which retained the session object
        // It is the responsibility of all those objects which retained the session
        // object to check for invalidity.
        [self.session invalidate];

        IMUTLogMain(@"Recorded %.2f seconds", self.session.sessionDuration);

        // Post global notification
        [IMUTLibUtil postNotificationName:IMUTLibDidInvalidateSessionNotification
                                   object:self
                             onMainThread:NO
                            waitUntilDone:YES];
    }
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
    id session;

    OSSpinLockLock(&sessionLock);
    session = objc_getAssociatedObject(self, @selector(session));
    OSSpinLockUnlock(&sessionLock);

    return session;
}

- (BOOL)isTerminated {
    return objc_getAssociatedObject(self, @selector(isTerminated)) != nil;
}

- (void)doStart {
    // Aquire lock during startup
    NSAssert(OSSpinLockTry(&notificationLock), @"Unable to aquire startup lock.");

    // Initial state
    started = NO;
    paused = NO;

    // Listen for runtime notifications as early as possible
    [self observeNotifications];

    static dispatch_once_t startOnceToken;
    dispatch_once(&startOnceToken, ^{
        // Invoke start procedure in a dedicated thread
        dispatch_async(mainImutDispatchQueue(DISPATCH_QUEUE_PRIORITY_LOW), ^{
            // Make sure all core objects did initialize
            [IMUTLibSourceEventQueue sharedInstance];
            [IMUTLibEventAggregatorRegistry sharedInstance];
            [IMUTLibModuleRegistry sharedInstance];

            // Set the sync time interval
            NSTimeInterval syncTimeInterval = [[self.config valueForConfigKey:kIMUTLibConfigSynchronizationTimeInterval
                                                                      default:@0.25] doubleValue];
            [IMUTLibEventSynchronizer sharedInstance].syncTimeInterval = syncTimeInterval;

            // Remove old, unfinished files
            if (![[self.config valueForConfigKey:kIMUTLibConfigKeepUnfinishedFiles default:numNO] boolValue]) {
                [IMUTLibFileManager removeTemporaryFiles];
            }

#if DEBUG
            // Remove old files by date (now-5 minutes)
            [IMUTLibFileManager removeAllFilesCreatedBeforeDate:[[NSDate date] dateByAddingTimeInterval:(-5.0 * 60)]];
#endif

            // Enable modules
            [self enableModules];

            // Create the first session
            [self createNewSession];

            // Tell all modules to start
            [IMUTLibUtil postNotificationName:IMUTLibWillStartNotification
                                       object:self
                                 onMainThread:NO
                                waitUntilDone:YES];

            // We are ready
            started = YES;

            // Release the lock
            OSSpinLockUnlock(&notificationLock);
        });
    });
}

@end
