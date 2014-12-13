#import "IMUTLibMediaSource+FrameRateCalculation.h"

@implementation IMUTLibMediaSource (FrameRateCalculation)

- (void)_calculateFrameRateWithCurrentFrameTime:(CMTime)time; {
    if(!_previousSecTimestamps) {
        _previousSecTimestamps = [NSMutableArray array];
    }

    [_previousSecTimestamps addObject:[NSValue valueWithCMTime:time]];

    CMTime oneSecond = CMTimeMake(1, 1);
    CMTime oneSecondAgo = CMTimeSubtract(time, oneSecond);

    while (CMTIME_COMPARE_INLINE([_previousSecTimestamps[0] CMTimeValue], <=, oneSecondAgo)) {
        [_previousSecTimestamps removeObjectAtIndex:0];
    }

    _currentFrameRate = (_currentFrameRate + [_previousSecTimestamps count]) / 2.0;
}

- (void)_resetCalculatedFrameRate {
    _previousSecTimestamps = nil;
    _currentFrameRate = 0;
}

@end
