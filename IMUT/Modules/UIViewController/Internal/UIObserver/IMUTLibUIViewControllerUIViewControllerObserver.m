#import "IMUTLibUIViewControllerUIViewControllerObserver.h"

@implementation IMUTLibUIViewControllerUIViewControllerObserver

+ (void)observe:(UINavigationController *)object {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[UIViewController class] __IMUT_integrateMethodFromSourceClass:[self class]
                                                     withSourceSelector:@selector(dismissViewControllerAnimated:completion:)];

        [[UIViewController class] __IMUT_integrateMethodFromSourceClass:[self class]
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

            if (completion) {
                completion();
            }
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

            if (completion) {
                completion();
            }
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
