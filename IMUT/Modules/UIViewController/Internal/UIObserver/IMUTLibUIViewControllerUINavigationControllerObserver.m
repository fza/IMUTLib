#import <UIKit/UIKit.h>

#import "IMUTLibUIViewControllerUINavigationControllerObserver.h"

#pragma mark UINavigationControllerDelegate handling

@interface IMUTLibUINavigationControllerDelegateConcrete : NSObject <UINavigationControllerDelegate>

@end

@implementation IMUTLibUINavigationControllerDelegateConcrete

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    IMUTLibUIViewControllerModule *module = (IMUTLibUIViewControllerModule *) [[IMUTLibModuleRegistry sharedInstance] moduleInstanceWithName:kIMUTLibUIViewControllerModule];
    [module inspectViewController:navigationController];

    if ([self respondsToSelector:@selector(original_navigationController:willShowViewController:animated:)]) {
        [self original_navigationController:navigationController
                     willShowViewController:viewController
                                   animated:animated];
    }
}

// stand-in dummy method
- (void)original_navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    IMUTLibUIViewControllerModule *module = (IMUTLibUIViewControllerModule *) [[IMUTLibModuleRegistry sharedInstance] moduleInstanceWithName:kIMUTLibUIViewControllerModule];
    [module inspectViewController:navigationController];

    if ([self respondsToSelector:@selector(original_navigationController:didShowViewController:animated:)]) {
        [self navigationController:navigationController
             didShowViewController:viewController
                          animated:animated];
    }
}

// stand-in dummy method
- (void)original_navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
}

@end

#pragma mark UINavigationController handling

@implementation IMUTLibUIViewControllerUINavigationControllerObserver

+ (void)observe:(UINavigationController *)object {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[UINavigationController class] __IMUT_integrateMethodFromSourceClass:[IMUTLibUIViewControllerUINavigationControllerObserver class]
                                                           withSourceSelector:@selector(setDelegate:)];

        if (object.delegate) {
            [object setDelegate:object.delegate];
        }
    });
}

- (void)setDelegate:(id <UITabBarControllerDelegate>)delegate {
    [[delegate class] __IMUT_integrateMethodFromSourceClass:[IMUTLibUINavigationControllerDelegateConcrete class]
                                         withSourceSelector:@selector(navigationController:didShowViewController:animated:)];

    [self original_setDelegate:delegate];
}

// stand-in dummy method
- (void)original_setDelegate:(id <UITabBarControllerDelegate>)delegate {
}

@end

CONSTRUCTOR {
    [[IMUTLibUIViewControllerObserverRegistry sharedInstance] registerObserverClass:[IMUTLibUIViewControllerUINavigationControllerObserver class]
                                                                         forUIClass:[UINavigationController class]];
}
