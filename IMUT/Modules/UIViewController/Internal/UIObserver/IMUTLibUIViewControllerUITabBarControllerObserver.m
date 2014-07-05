#import <UIKit/UIKit.h>

#import "IMUTLibUIViewControllerUITabBarControllerObserver.h"

#pragma mark UITabBarControllerDelegate handling

@interface IMUTLibUITabBarControllerDelegate : NSObject <UITabBarControllerDelegate>

@end

@implementation IMUTLibUITabBarControllerDelegate

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    IMUTLibUIViewControllerModule *module = (IMUTLibUIViewControllerModule *) [[IMUTLibModuleRegistry sharedInstance] moduleInstanceWithName:kIMUTLibUIViewControllerModule];

    [module inspectViewController:tabBarController];

    if ([self respondsToSelector:@selector(original_tabBarController:didSelectViewController:)]) {
        [self original_tabBarController:tabBarController
                didSelectViewController:viewController];
    }
}

// stand-in dummy method
- (void)original_tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
}

@end

#pragma mark UITabBarController handling

@implementation IMUTLibUITabBarControllerObserver

+ (void)observe:(UITabBarController *)object {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[UITabBarController class] __IMUT_integrateMethodFromSourceClass:[self class]
                                                       withSourceSelector:@selector(setDelegate:)];

        if (object.delegate) {
            [object setDelegate:object.delegate];
        }
    });
}

- (void)setDelegate:(id)delegate {
    [[delegate class] __IMUT_integrateMethodFromSourceClass:[IMUTLibUITabBarControllerDelegate class]
                                         withSourceSelector:@selector(tabBarController:didSelectViewController:)];

    [self original_setDelegate:delegate];
}

// stand-in dummy method
- (void)original_setDelegate:(id)delegate {
}

@end

#pragma mark Initializer

CONSTRUCTOR {
    [[IMUTLibUIViewControllerObserverRegistry sharedInstance] registerObserverClass:[IMUTLibUITabBarControllerObserver class]
                                                                         forUIClass:[UITabBarController class]];
}
