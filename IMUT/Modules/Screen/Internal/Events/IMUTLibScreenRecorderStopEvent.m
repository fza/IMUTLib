#import "IMUTLibScreenRecorderStopEvent.h"
#import "IMUTLibScreenModuleConstants.h"
#import "IMUTLibFunctions.h"

@implementation IMUTLibScreenRecorderStopEvent {
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
    return kIMUTLibScreenModuleRecorderStopEvent;
}

- (NSDictionary *)parameters {
    return @{
//        kIMUTLibScreenModuleRecorderStopEventParamDuration : formatCMTime(_sampleTime),
        kIMUTLibScreenModuleRecorderStopEventParamFilename : _filename
    };
}

@end
