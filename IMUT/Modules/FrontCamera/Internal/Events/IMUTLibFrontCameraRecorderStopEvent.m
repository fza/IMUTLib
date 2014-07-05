#import "IMUTLibFrontCameraRecorderStopEvent.h"
#import "IMUTLibFrontCameraModuleConstants.h"
#import "IMUTLibFunctions.h"

@implementation IMUTLibFrontCameraRecorderStopEvent {
    CMTime _sampleTime;
    NSString *_filename;
}

- (instancetype)initWithSampleTime:(CMTime)sampleTime filename:(NSString *)filename {
    if (self = [super init]) {
        _sampleTime = sampleTime;
        _filename = filename;
    }

    return self;
}

#pragma mark IMUTLibSourceEvent protocol

- (NSString *)eventName {
    return kIMUTLibFrontCameraModuleRecorderStopEvent;
}

- (NSDictionary *)parameters {
    return @{
        kIMUTLibFrontCameraModuleRecorderStopEventParamDuration : formatCMTime(_sampleTime),
        kIMUTLibFrontCameraModuleRecorderStopEventParamFilename : _filename
    };
}

@end
