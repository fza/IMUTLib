#import <Foundation/Foundation.h>

#import "IMUTLibModule.h"
#import "IMUTLibScreenModuleDelegate.h"
#import "IMUTLibPollingVideoSource.h"
#import "IMUTLibDeviceCapturingSource.h"

@interface IMUTLibFrontCameraModule : IMUTLibModule

@property(nonatomic, readonly, retain) IMUTLibMediaWriter *mediaWriter;

@property(nonatomic, readonly, retain) IMUTLibDeviceCapturingSource *videoSource;

- (BOOL)startRecording;

- (void)stopRecording;

@end
