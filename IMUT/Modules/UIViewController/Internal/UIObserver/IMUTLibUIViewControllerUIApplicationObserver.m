#import <UIKit/UIKit.h>

#import "IMUTLibUIViewControllerUIApplicationObserver.h"

@implementation IMUTLibUIViewControllerUIApplicationObserver

+ (void)observe:(UIApplication *)object {
    // NOOP
}

@end

CONSTRUCTOR {
    [[IMUTLibUIViewControllerObserverRegistry sharedInstance] registerObserverClass:[IMUTLibUIViewControllerUIApplicationObserver class]
                                                                         forUIClass:[UIApplication class]];
}
