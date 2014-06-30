#import <CoreMedia/CoreMedia.h>
#import <Foundation/Foundation.h>
#import "IMUTLibMediaEncoder.h"

typedef NS_ENUM(NSUInteger, IMUTLibPixelBufferPopulationStatus) {
    IMUTLibPixelBufferPopulationStatusSuccess = 0,
    IMUTLibPixelBufferPopulationStatusFailure = 1
};


typedef NS_ENUM(NSUInteger, IMUTLibVideoEncodingFailedReason) {
    IMUTLibVideoEncodingFailedReasonUnknown = 0,
    IMUTLibVideoEncodingFailedNoDataToEncode = 1,
    IMUTLibVideoEncodingFailedInternal = 2
};

@class IMUTLibVideoEncoder;

@protocol IMUTLibMediaEncoderVideoDelegate

// The encoder asks its `inputDelegate` to populate the given pixel buffer, which is then encoded.
// This is a somewhat unusual architecture, but allows us to let the encoder decide if and when
// new source data needs to be generated.
- (IMUTLibPixelBufferPopulationStatus)forEncoder:(IMUTLibVideoEncoder *)encoder
                        renderFrameInPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@optional
// Called when the encoder failed to process a frame. This is called asynchronously.
- (void)encoder:(IMUTLibVideoEncoder *)encoder failedEncodingFrameWithTiming:(IMFrameTimingRef)timing reason:(IMUTLibVideoEncodingFailedReason)reason;

// Called when the encoder processed a frame. This is called asynchronously.
- (void)encoder:(IMUTLibVideoEncoder *)encoder didEncodeFrameWithTiming:(IMFrameTimingRef)timing;

// Called when frames were dropped. This is called asynchronously.
- (void)encoder:(IMUTLibVideoEncoder *)encoder droppedFrames:(NSUInteger)droppedFrames;

// Called when the encoder needs to know the correct video settings
- (void)forEncoder:(IMUTLibVideoEncoder *)encoder checkVideoSettings:(NSMutableDictionary *)videoSettings;

// Called when the encoder needs to know how to create pixel buffers
- (void)forEncoder:(IMUTLibVideoEncoder *)encoder checkBufferAttributes:(NSMutableDictionary *)bufferAttributes;

@end

@interface IMUTLibVideoEncoder : NSObject <IMUTLibMediaEncoder>

// The input delegate to ask for pixel data
@property(nonatomic, readonly, weak) id <IMUTLibMediaEncoderVideoDelegate> inputDelegate;

+ (instancetype)videoEncoderWithInputDelegate:(id <IMUTLibMediaEncoderVideoDelegate>)inputDelegate;

@end
