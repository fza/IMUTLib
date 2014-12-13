#import <Foundation/Foundation.h>

#import "IMUTLibMediaSource.h"

@interface IMUTLibMediaSource (FrameRateCalculation)

- (void)_calculateFrameRateWithCurrentFrameTime:(CMTime)time;

- (void)_resetCalculatedFrameRate;

@end
