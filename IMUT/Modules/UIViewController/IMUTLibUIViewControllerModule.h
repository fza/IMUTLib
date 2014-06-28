#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "IMUTLibAbstractModule.h"
#import "IMUTLibEventAggregator.h"
#import "IMUTLibUIViewControllerChangeEvent.h"

@interface IMUTLibUIViewControllerModule : IMUTLibAbstractModule <IMUTLibEventAggregator>

- (IMUTLibUIViewControllerChangeEvent *)sourceEventWithViewController:(UIViewController *)viewController;

@end
