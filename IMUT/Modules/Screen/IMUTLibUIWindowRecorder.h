#import <Foundation/Foundation.h>
#import "IMUTLibMediaFrameBasedVideoEncoder.h"
#import "IMUTLibMediaStreamWriter.h"

@interface IMUTLibUIWindowRecorder : NSObject <IMUTLibMediaEncoderVideoDelegate>

@property(nonatomic, readonly, retain) NSDate *dateOfFirstFrame;

@property(nonatomic, readonly, retain) IMUTLibMediaFrameBasedVideoEncoder *mediaEncoder;

@property(nonatomic, readonly, assign) double duration;

+ (instancetype)recorderWithMediaStreamWriter:(IMUTLibMediaStreamWriter *)mediaStreamWriter config:(NSDictionary *)config;

- (void)resetDuration;

- (void)startRecording;

- (void)stopRecording;

@end
