#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "IMUTLibUIViewControllerModule.h"
#import "IMUTLibUIViewControllerChangeEvent.h"

@interface IMUTLibUIViewControllerModule (SourceEventGeneration)

- (void)startSourceEventGeneration;

- (void)stopSourceEventGeneration;

- (void)inspectViewController:(UIViewController *)viewController;

- (void)rebuildEntireObjectHierarchy;

- (UIViewController *)frontMostViewController;

- (IMUTLibUIViewControllerChangeEvent *)sourceEventWithViewController:(UIViewController *)viewController;

@end
