#import <CoreMedia/CMSync.h>

#import "IMUTLibDefaultSessionTimer.h"
#import "IMUTLibConstants.h"

NSUInteger IMUTLibDefaultSessionTimerPreference = 0;

@implementation IMUTLibDefaultSessionTimer {
    BOOL _ticking;
    NSTimeInterval _lastDuration;
    CMTimebaseRef _timebase;
};

#pragma mark IMUTLibSessionTimer protocol

+ (NSUInteger)preference {
    return IMUTLibDefaultSessionTimerPreference;
}

- (instancetype)init {
    if (self = [super init]) {
        _ticking = NO;
        _timebase = NULL;
        _lastDuration = 0;
    }

    return self;
}

- (NSString *)description {
    return kDefaultSessionTimer;
}

- (NSTimeInterval)duration {
    if (_ticking) {
        return (double) CMTimeGetSeconds(CMTimebaseGetTime(_timebase));
    }

    return _lastDuration;
}

- (void)startTickingWithCompletionBlock:(void (^)(BOOL started))completionBlock {
    @synchronized (self) {
        if (_ticking) {
            completionBlock(NO);
        }

        CMTimebaseCreateWithMasterClock(
            kCFAllocatorDefault,
            CMClockGetHostTimeClock(),
            &_timebase
        );

        CMTimebaseSetRate(_timebase, 1.0);
        CMTimebaseSetTime(_timebase, CMTimeMake(0, 1000 * 1000));

        _ticking = YES;

        completionBlock(YES);
    }
}

- (void)stopTickingWithCompletionBlock:(void (^)(BOOL stopped))completionBlock {
    @synchronized (self) {
        if (!_ticking) {
            completionBlock(NO);
        }

        _lastDuration = [self duration];
        _timebase = NULL;
        _ticking = NO;

        completionBlock(YES);
    }
}

@end
