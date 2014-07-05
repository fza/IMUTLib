#import <CoreMedia/CMSync.h>

#import "IMUTLibScreenModuleSessionTimer.h"
#import "IMUTLibScreenModuleConstants.h"
#import "IMUTLibModuleRegistry.h"
#import "IMUTLibScreenModule.h"

@implementation IMUTLibScreenModuleSessionTimer {
    IMUTLibScreenModule *_screenModule;

    BOOL _starting;
    BOOL _stopping;
    BOOL _ticking;

    void(^_startCompletionBlock)(BOOL started);

    void(^_stopCompletionBlock)(BOOL stopped);
}

+ (NSUInteger)preference {
    return 1024;
}

+ (NSString *)description {
    return kIMUTLibScreenModule;
}

- (instancetype)init {
    if (self = [super init]) {
        _screenModule = (IMUTLibScreenModule *) [[IMUTLibModuleRegistry sharedInstance] moduleInstanceWithName:kIMUTLibScreenModule];
        _screenModule.delegate = self;

        _starting = NO;
        _stopping = NO;
        _ticking = NO;
    }

    return self;
}

- (NSTimeInterval)duration {
    CMTime time;

    if (_screenModule.videoSource.capturing) {
        time = CMTimebaseGetTime(_screenModule.videoSource.currentTimebase);
    } else {
        time = _screenModule.videoSource.lastSampleTime;
    }

    return (NSTimeInterval) CMTimeGetSeconds(time);
}

- (void)startTickingWithCompletionBlock:(void (^)(BOOL started))completionBlock {
    @synchronized (self) {
        if (!_starting && !_ticking) {
            _starting = YES;
            _startCompletionBlock = completionBlock;

            if (![_screenModule startRecording]) {
                _starting = NO;
                completionBlock(NO);
            }
        } else {
            completionBlock(NO);
        }
    }
}

- (void)stopTickingWithCompletionBlock:(void (^)(BOOL stopped))completionBlock {
    @synchronized (self) {
        if (!_starting && _ticking && !_stopping) {
            _stopping = YES;
            _stopCompletionBlock = completionBlock;

            [_screenModule stopRecording];
        } else {
            completionBlock(NO);
        }
    }
}

#pragma mark IMUTLibScreenModuleRecordingDelegate

// Only after the first frame was created the clock started ticking
- (void)recorder:(NSObject *)recorder createdNewFrameAtTime:(NSTimeInterval)time {
    if (_starting) {
        _ticking = YES;
        _starting = NO;

        if (_startCompletionBlock) {
            _startCompletionBlock(YES);
            _startCompletionBlock = nil;
        }
    }
}

// Only when the media file is about to be finalized the clock may stop ticking
- (void)recorder:(NSObject *)recorder willFinalizeCurrentMediaFileAtPath:(NSString *)path {
    if (_stopping) {
        _ticking = NO;
        _stopping = NO;

        if (_stopCompletionBlock) {
            _stopCompletionBlock(YES);
            _stopCompletionBlock = nil;
        }
    }
}

@end
