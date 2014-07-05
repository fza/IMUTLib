#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "IMUTLibSourceEvent.h"

@interface IMUTLibDeviceOrientationChangeEvent : NSObject <IMUTLibSourceEvent>

- (instancetype)initWithCurrentOrientation;

- (instancetype)initWithOrientation:(UIDeviceOrientation)orientation;

- (UIDeviceOrientation)orientation;

- (NSString *)orientationString;

@end
