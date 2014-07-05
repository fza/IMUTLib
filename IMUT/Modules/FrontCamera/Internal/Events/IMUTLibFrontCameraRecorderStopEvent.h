#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

#import "IMUTLibSourceEvent.h"

@interface IMUTLibFrontCameraRecorderStopEvent : NSObject <IMUTLibSourceEvent>

- (instancetype)initWithSampleTime:(CMTime)sampleTime filename:(NSString *)filename;

@end
