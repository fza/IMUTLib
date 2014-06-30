#import "IMUTLibScreenModule.h"
#import "IMUTLibUIWindowRecorder.h"
#import "IMUTLibMediaStreamManager.h"
#import "IMUTLibScreenModuleConstants.h"
#import "IMUTLibConstants.h"
#import "IMUTLibMain.h"

@implementation IMUTLibScreenModule {
    IMUTLibUIWindowRecorder *_recorder;
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
        [_recorder addObserver:self
                    forKeyPath:@"recordingStartDate"
                       options:NSKeyValueObservingOptionNew
                       context:NULL];
    }

    return self;
}

+ (NSDictionary *)defaultConfig {
    return @{
        kIMUTLibScreenModuleConfigHidePasswordInput : numYES,
        kIMUTLibScreenModuleConfigUseLowResolution : numNO
    };
}

- (void)pause {
    [self stopTicking];
}

#pragma mark IMUTLibTimeSource protocol

+ (NSNumber *)timeSourcePreference {
    return @1024;
}

- (NSString *)timeSourceInfo {
    return kIMUTLibScreenModule;
}

- (NSDate *)startDate {
    return _recorder.recordingStartDate;
}

- (NSTimeInterval)intervalSinceClockStart {
    if (_recorder.recordingStartDate) {
        return _recorder.recordingDuration;
    }

    return 0;
}

- (BOOL)startTicking {
    return [_recorder startRecording];
}

- (void)stopTicking {
    [_recorder stopRecording];
}

#pragma mark Private

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == _recorder && [keyPath isEqualToString:@"recordingStartDate"]) {
        id value = change[NSKeyValueChangeNewKey];
        if (value == nil || value == [NSNull null]) {
            [self.timeSourceDelegate clockDidStopAfterTimeInterval:_recorder.lastRecordingDuration];
        } else {
            [self.timeSourceDelegate clockDidStartAtDate:change[@"new"]];
        }
    }
}

@end

CONSTRUCTOR {
    [IMUTLibMain registerModuleWithClass:[IMUTLibScreenModule class]];
}
