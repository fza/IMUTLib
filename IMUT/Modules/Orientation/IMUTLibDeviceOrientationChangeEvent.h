#import <Foundation/Foundation.h>
#import "IMUTLibSourceEvent.h"

@interface IMUTLibDeviceOrientationChangeEvent : NSObject <IMUTLibSourceEvent>

- (instancetype)initWithCurrentOrientation;

- (instancetype)initWithOrientation:(UIDeviceOrientation)orientation;

- (UIDeviceOrientation)orientation;

- (NSString *)orientationString;

@end
