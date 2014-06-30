#import <Foundation/Foundation.h>
#import "IMUTLibVideoEncoder.h"
#import "IMUTLibMediaStreamWriter.h"

@interface IMUTLibUIWindowRecorder : NSObject <IMUTLibMediaEncoderVideoDelegate>

@property(atomic, readonly, retain) NSDate *recordingStartDate;

@property(nonatomic, readonly, assign) NSTimeInterval recordingDuration;

@property(nonatomic, readonly, assign) NSTimeInterval lastRecordingDuration;

+ (instancetype)recorderWithMediaStreamWriter:(IMUTLibMediaStreamWriter *)mediaStreamWriter config:(NSDictionary *)config;

- (BOOL)startRecording;

- (void)stopRecording;

@end
