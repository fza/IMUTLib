#import <CoreMedia/CoreMedia.h>
#import <Foundation/Foundation.h>
#import "IMUTLibMediaEncoder.h"

@class IMUTLibMediaFrameBasedVideoEncoder;

@protocol IMUTLibMediaEncoderVideoDelegate

- (BOOL)encoder:(IMUTLibMediaFrameBasedVideoEncoder* )encoder populatePixelBuffer:(CVPixelBufferRef)pixelBuffer forTime:(CMTime)frameTime;

@optional
- (void)encoder:(IMUTLibMediaFrameBasedVideoEncoder* )encoder videoSettings:(NSMutableDictionary *)videoSettings;

- (void)encoder:(IMUTLibMediaFrameBasedVideoEncoder* )encoder bufferAttributes:(NSMutableDictionary *)bufferAttributes;

- (void)encoder:(IMUTLibMediaFrameBasedVideoEncoder* )encoder droppedFrames:(NSUInteger)droppedFrames;

@end

@interface IMUTLibMediaFrameBasedVideoEncoder : NSObject <IMUTLibMediaEncoder>

@property(nonatomic, readonly, assign) IMUTLibMediaSourceType mediaSourceType;
@property(nonatomic, readonly, retain) AVAssetWriterInput *writerInput;
@property(nonatomic, readonly, assign) CMTime duration;
@property(nonatomic, readonly, assign) BOOL stopped;
@property(nonatomic, readonly, retain) NSDate *dateOfFirstFrame;

// Connected to the module
@property(nonatomic, readonly, weak) id <IMUTLibMediaEncoderVideoDelegate> inputDelegate;

// Connected to the stream writer
@property(nonatomic, readwrite, weak) id <IMUTLibMediaEncoderDelegate> delegate;

+ (instancetype)videoEncoderWithInputDelegate:(id <IMUTLibMediaEncoderVideoDelegate>)inputDelegate
                                      andName:(NSString *)name;

- (void)startTimer;

- (void)stopTimer;

@end
