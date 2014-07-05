#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

#import "IMUTLibSourceEvent.h"

@interface IMUTLibScreenRecorderStopEvent : NSObject <IMUTLibSourceEvent>

- (instancetype)initWithSampleTime:(CMTime)sampleTime filename:(NSString *)filename;

@end
