#import <UIKit/UIKit.h>
#import "IMUTLibMain+Internal.h"
#import "IMUTLibConstants.h"
#import "IMUTLibFileManager.h"
#import "IMUTLibSourceEventQueue.h"
#import "IMUTLibUtil.h"
#import "IMUTLibEventAggregatorRegistry.h"

static BOOL paused;

@interface IMUTLibMain (InternalPrivate)

- (void)enableModules;

- (void)observeNotifications;

- (void)applicationWillResignActiveNotification:(NSNotification *)notification;

- (void)applicationDidBecomeActiveNotification:(NSNotification *)notification;

- (void)applicationWillTerminateNotification:(NSNotification *)notification;

- (void)postNotificationWithName:(NSString *)notificationName;

- (void)postNotification:(NSNotification *)notification;

- (void)createNewSession;

- (void)invalidateCurrentSession;

@end

#pragma mark Internal private methods

@implementation IMUTLibMain (InternalPrivate)

- (void)enableModules {
    [[IMUTLibModuleRegistry sharedInstance] enableModulesWithConfigs:[self.config moduleConfigs]];
}

- (void)observeNotifications {
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];

    [defaultCenter addObserver:self
                      selector:@selector(applicationWillResignActiveNotification:)
                          name:UIApplicationWillResignActiveNotification
                        object:nil];

    [defaultCenter addObserver:self
                      selector:@selector(applicationDidBecomeActiveNotification:)
                          name:UIApplicationDidBecomeActiveNotification
                        object:nil];

    [defaultCenter addObserver:self
                      selector:@selector(applicationWillTerminateNotification:)
                          name:UIApplicationWillTerminateNotification
                        object:nil];
}

- (void)applicationWillResignActiveNotification:(NSNotification *)notification {
    @synchronized (self) {
        if (paused || [self isTerminated]) {
            return;
        }

        paused = YES;

        [self postNotificationWithName:IMUTLibWillPauseNotification];
        [self invalidateCurrentSession];
    }
}

- (void)applicationDidBecomeActiveNotification:(NSNotification *)notification {
    @synchronized (self) {
        if (!paused || [self isTerminated]) {
            return;
        }

        paused = NO;

        [self createNewSession];
        [self postNotificationWithName:IMUTLibDidResumeNotification];
    }
}

- (void)applicationWillTerminateNotification:(NSNotification *)notification {
    @synchronized (self) {
        objc_setAssociatedObject(self, @selector(isTerminated), cYES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

        [self postNotificationWithName:IMUTLibWillTerminateNotification];
        [self invalidateCurrentSession];
    }
}

- (void)postNotificationWithName:(NSString *)notificationName {
    [self postNotification:[NSNotification notificationWithName:notificationName
                                                         object:self]];
}

- (void)postNotification:(NSNotification *)notification {
    [IMUTLibUtil postNotificationOnMainThreadWithNotificationName:notification.name
                                                           object:notification.object
                                                    waitUntilDone:YES];
}

- (void)createNewSession {
    @synchronized (self) {
        if (self.session) {
            [self invalidateCurrentSession];
        }

        // Create new session
        IMUTLibSession *newSession = [IMUTLibSession sessionWithTimeSource:[IMUTLibModuleRegistry sharedInstance].bestTimeSource];
        objc_setAssociatedObject(self, @selector(session), newSession, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

        // Post global notification
        [self postNotification:[NSNotification notificationWithName:IMUTLibDidSessionCreateNotification
                                                             object:self.session]];
    }
}

- (void)invalidateCurrentSession {
    @synchronized (self) {
        if (self.session) {
            // Set invalid flag for all those objects which retained the session object
            [self.session invalidate];

            // Set the session object to nil
            objc_setAssociatedObject(self, @selector(session), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
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

    return self.config != nil;
}

- (IMUTLibConfig *)config {
    return objc_getAssociatedObject(self, @selector(config));
}

- (IMUTLibSession *)session {
    return objc_getAssociatedObject(self, @selector(session));
}

- (BOOL)isTerminated {
    return objc_getAssociatedObject(self, @selector(isTerminated)) != nil;
}

- (void)doStart {
    // Invoke start procedure in a dedicated thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @synchronized (self) {
            paused = NO;

            // Make sure all core objects did initialize
            [IMUTLibSourceEventQueue sharedInstance];
            [IMUTLibEventAggregatorRegistry sharedInstance];
            [IMUTLibModuleRegistry sharedInstance];

            // Set the sync time interval
            [IMUTLibEventSynchronizer sharedInstance].syncTimeInterval = [[self.config valueForConfigKey:kIMUTLibConfigSynchronizationTimeInterval
                                                                                                 default:@0.25] doubleValue];

            // Remove old, unfinished files
            if (![[self.config valueForConfigKey:kIMUTLibConfigKeepUnfinishedFiles default:cNO] boolValue]) {
                [IMUTLibFileManager removeTemporaryFiles];
            }

#if DEBUG
            // Remove old files by date (now-5 minutes)
            [IMUTLibFileManager removeAllFilesCreatedBeforeDate:[[NSDate date] dateByAddingTimeInterval:(-5.0 * 60)]];
#endif

            // Enable modules
            [self enableModules];

            // Listen for runtime notifications
            [self observeNotifications];

            // Create the first session
            [self createNewSession];

            // Tell all listeners that the main initialization is ready
            [self postNotificationWithName:IMUTLibWillStartNotification];
        }
    });
}

@end
