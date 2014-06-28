#import <UIKit/UIKit.h>
#import "IMUTLibModuleRegistry.h"
#import "IMUTLibUIViewControllerModule+SourceEventGeneration.h"
#import "IMUTLibUIViewControllerObserverRegistry.h"
#import "IMUTLibUIViewControllerUINavigationControllerObserver.h"
#import "IMUTLibUIViewControllerModuleConstants.h"
#import "NSObject+IMUTLibClassExtension.h"

#pragma mark UINavigationControllerDelegate handling

@interface IMUTLibUINavigationControllerDelegate : NSObject <UINavigationControllerDelegate>

@end

@implementation IMUTLibUINavigationControllerDelegate

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
    [[delegate class] __IMUT_integrateMethodFromSourceClass:[IMUTLibUINavigationControllerDelegate class]
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
