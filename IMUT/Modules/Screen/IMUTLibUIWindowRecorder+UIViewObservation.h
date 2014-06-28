#import <Foundation/Foundation.h>
#import "IMUTLibUIWindowRecorder.h"

@interface IMUTLibUIWindowRecorder (UIViewObservation)

+ (UIView *)activeUIStatusBar;

+ (UITextField *)activeSecureUITextField;

@end
