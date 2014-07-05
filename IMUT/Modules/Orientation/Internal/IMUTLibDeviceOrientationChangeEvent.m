#import <UIKit/UIKit.h>

#import "IMUTLibDeviceOrientationChangeEvent.h"
#import "IMUTLibOrientationModuleConstants.h"

@interface IMUTLibDeviceOrientationChangeEvent ()

- (BOOL)isValidOrientation:(UIDeviceOrientation)orientation;

@end

@implementation IMUTLibDeviceOrientationChangeEvent {
    UIDeviceOrientation _orientation;
}

- (instancetype)initWithCurrentOrientation {
    return [self initWithOrientation:[UIDevice currentDevice].orientation];
}

- (instancetype)initWithOrientation:(UIDeviceOrientation)orientation {
    if (self = [super init]) {
        if ([self isValidOrientation:orientation]) {
            _orientation = orientation;

            return self;
        }
    }

    return nil;
}

- (UIDeviceOrientation)orientation {
    return _orientation;
}

- (NSString *)orientationString {
    switch (_orientation) {
        case UIDeviceOrientationPortrait:
            return kIMUTLibOrientationChangeEventParamOrientationValPortrait;

        case UIDeviceOrientationPortraitUpsideDown:
            return kIMUTLibOrientationChangeEventParamOrientationValPortraitUpsideDown;

        case UIDeviceOrientationLandscapeLeft:
            return kIMUTLibOrientationChangeEventParamOrientationValPortraitLandscapeLeft;

        case UIDeviceOrientationLandscapeRight:
            return kIMUTLibOrientationChangeEventParamOrientationValPortraitLandscapeRight;

        default:
            return nil;
    }
}

#pragma mark IMUTLibSourceEvent protocol

- (NSString *)eventName {
    return kIMUTLibDeviceOrientationChangeEvent;
}

- (NSDictionary *)parameters {
    return @{
        kIMUTLibOrientationChangeEventParamOrientation : [self orientationString]
    };
}

#pragma mark Private

- (BOOL)isValidOrientation:(UIDeviceOrientation)orientation {
    return orientation == UIDeviceOrientationPortrait ||
        orientation == UIDeviceOrientationPortraitUpsideDown ||
        orientation == UIDeviceOrientationLandscapeLeft ||
        orientation == UIDeviceOrientationLandscapeRight;
}

@end
