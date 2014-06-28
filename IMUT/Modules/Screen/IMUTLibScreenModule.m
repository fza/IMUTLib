#import "IMUTLibScreenModule.h"
#import "IMUTLibUIWindowRecorder.h"
#import "IMUTLibMediaStreamManager.h"
#import "IMUTLibScreenModuleConstants.h"
#import "IMUTLibConstants.h"
#import "IMUTLibMain.h"
#import "IMUTLibUtil.h"

@implementation IMUTLibScreenModule {
    IMUTLibUIWindowRecorder *_recorder;
    double _referenceTime;
}

#pragma mark IMUTLibModule protocol

+ (NSString *)moduleName {
    return kIMUTLibScreenModule;
}

+ (IMUTLibModuleType)moduleType {
    return IMUTLibModuleTypeStream;
}

- (instancetype)initWithConfig:(NSDictionary *)config {
    if (self = [super initWithConfig:config]) {
        IMUTLibMediaStreamWriter *mediaStreamWriter = [[IMUTLibMediaStreamManager sharedInstance] writerWithBasename:@"screen"];
        _recorder = [IMUTLibUIWindowRecorder recorderWithMediaStreamWriter:mediaStreamWriter config:config];
        [_recorder.mediaEncoder addObserver:self
                                 forKeyPath:@"dateOfFirstFrame"
                                    options:NSKeyValueObservingOptionNew
                                    context:NULL];
    }

    return self;
}

+ (NSDictionary *)defaultConfig {
    return @{
        kIMUTLibScreenModuleConfigHidePasswordInput : cYES,
        kIMUTLibScreenModuleConfigUseLowResolution : cNO
    };
}

- (void)start {
    [_recorder startRecording];
}

- (void)pause {
    [_recorder stopRecording];

    double duration = _recorder.duration;
    if (duration > 0) {
        IMUTLogMain(@"Recorded %.2f seconds using \"%@\"", _recorder.duration, [[self class] moduleName]);
    }
}

- (void)resume {
    [_recorder resetDuration];
    [self start];
}

- (void)terminate {
    [self pause];
}

#pragma mark IMUTLibTimeSource protocol

+ (NSNumber *)timeSourcePreference {
    return @1024;
}

- (NSString *)timeSourceInfo {
    return kIMUTLibScreenModule;
}

- (NSDate *)startDate {
    return _recorder.dateOfFirstFrame;
}

- (NSTimeInterval)intervalSinceClockStart {
    if(_recorder.dateOfFirstFrame) {
        return [IMUTLibUtil uptime] - _referenceTime;
    }

    return 0;
}

#pragma mark Private

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == _recorder.mediaEncoder && [keyPath isEqualToString:@"dateOfFirstFrame"]) {
        if (!_recorder.dateOfFirstFrame) {
            [self.timeSourceDelegate clockDidStop];
            _referenceTime = 0;
        } else {
            [self.timeSourceDelegate clockDidStartAtDate:change[@"new"]];
            _referenceTime = [IMUTLibUtil uptime];
        }
    }
}

@end

CONSTRUCTOR {
    [IMUTLibMain registerModuleWithClass:[IMUTLibScreenModule class]];
}
