#import <UIKit/UIKit.h>

#import "IMUTLibUIViewControllerUIWindowObserver.h"

#pragma mark UIWindow handling

@interface IMUTLibUIViewControllerUIWindowObserver ()

SINGLETON_INTERFACE

@end

@implementation IMUTLibUIViewControllerUIWindowObserver

SINGLETON

+ (void)observe:(UIWindow *)object {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[NSNotificationCenter defaultCenter] addObserver:[self sharedInstance]
                                                 selector:@selector(keyWindowDidChange:)
                                                     name:UIWindowDidBecomeKeyNotification
                                                   object:nil];
    });
}

- (void)keyWindowDidChange:(NSNotification *)notification {
    IMUTLibUIViewControllerModule *module = (IMUTLibUIViewControllerModule *) [[IMUTLibModuleRegistry sharedInstance] moduleInstanceWithName:kIMUTLibUIViewControllerModule];

    [module rebuildEntireObjectHierarchy];
}

@end

CONSTRUCTOR {
    [[IMUTLibUIViewControllerObserverRegistry sharedInstance] registerObserverClass:[IMUTLibUIViewControllerUIWindowObserver class]
                                                                         forUIClass:[UIWindow class]];
}
