#import <UIKit/UIKit.h>
#import "IMUTLibModuleRegistry.h"
#import "IMUTLibUIViewControllerModule+SourceEventGeneration.h"
#import "IMUTLibUIViewControllerObserverRegistry.h"
#import "IMUTLibUIViewControllerUIViewControllerObserver.h"
#import "IMUTLibUIViewControllerModuleConstants.h"
#import "NSObject+IMUTLibClassExtension.h"

@implementation IMUTLibUIViewControllerUIViewControllerObserver

+ (void)observe:(UINavigationController *)object {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[UINavigationController class] __IMUT_integrateMethodFromSourceClass:[self class]
                                                           withSourceSelector:@selector(dismissViewControllerAnimated:completion:)];

        [[UINavigationController class] __IMUT_integrateMethodFromSourceClass:[self class]
                                                           withSourceSelector:@selector(presentViewController:animated:completion:)];
    });
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    IMUTLibUIViewControllerModule *module = (IMUTLibUIViewControllerModule *) [[IMUTLibModuleRegistry sharedInstance] moduleInstanceWithName:kIMUTLibUIViewControllerModule];

    [module inspectViewController:(UIViewController *) (id) self];

    if ([self respondsToSelector:@selector(original_dismissViewControllerAnimated:completion:)]) {
        [self original_dismissViewControllerAnimated:flag completion:^{
            if (self) {
                [module inspectViewController:(UIViewController *) (id) self];
            }

            completion();
        }];
    }
}

// stand-in dummy method
- (void)original_dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
}

- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    IMUTLibUIViewControllerModule *module = (IMUTLibUIViewControllerModule *) [[IMUTLibModuleRegistry sharedInstance] moduleInstanceWithName:kIMUTLibUIViewControllerModule];

    [module inspectViewController:(UIViewController *) (id) self];

    if ([self respondsToSelector:@selector(original_presentViewController:animated:completion:)]) {
        [self original_presentViewController:viewControllerToPresent animated:flag completion:^{
            if (self) {
                [module inspectViewController:(UIViewController *) (id) self];
            }

            completion();
        }];
    }
}

// stand-in dummy method
- (void)original_presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
}

@end

CONSTRUCTOR {
    [[IMUTLibUIViewControllerObserverRegistry sharedInstance] registerObserverClass:[IMUTLibUIViewControllerUIViewControllerObserver class]
                                                                         forUIClass:[UIViewController class]];
}
