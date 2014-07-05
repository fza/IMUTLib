#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "IMUTLibScreenRenderer.h"

@interface IMUTLibScreenRenderer (UIViewObservation)

+ (UIView *)activeUIStatusBar;

+ (UITextField *)activeSecureUITextField;

// TODO
//+ (NSSet *)activeVideoPreviewLayers;

@end
