#import <Foundation/Foundation.h>

#import "IMUTLibMediaSource.h"

@protocol IMUTLibVideoCapturerDelegate;

@interface IMUTLibDeviceCapturingSource : IMUTLibMediaSource

@property(nonatomic, readwrite, retain) NSObject <IMUTLibVideoCapturerDelegate> *delegate;

+ (instancetype)captureSourceWithInputDevice:(AVCaptureDeviceInput *)inputDevice targetFrameRate:(unsigned int)targetFrameRate;

@end

@protocol IMUTLibVideoCapturerDelegate

// Called when the video source needs to know how to create pixel buffers
- (void)capturingSource:(IMUTLibDeviceCapturingSource *)capturingSource giveSessionPreset:(NSString **)sessionPreset;

- (NSDictionary *)videoSettingsUsingDefaults:(NSMutableDictionary *)videoSettings;

// Called when the video source needs to know how to create pixel buffers
- (NSDictionary *)bufferAttributesUsingDefaults:(NSMutableDictionary *)bufferAttributes;

@optional
// Called when the video source processed a frame. This is called asynchronously.
- (void)capturingSource:(IMUTLibDeviceCapturingSource *)capturingSource didProcessFrameAtTime:(CMTime)time;

@end
