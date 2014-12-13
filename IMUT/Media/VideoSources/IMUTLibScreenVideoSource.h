#import <Foundation/Foundation.h>

#import "IMUTLibMediaSource.h"

#define MAX_WAIT_TO_STOP_SECS 5.0

@protocol IMUTLibVideoRenderer;

typedef NS_ENUM(NSUInteger, IMUTLibVideoFrameRenderStatus) {
    IMUTLibVideoFrameStatusSuccess = 0,
    IMUTLibVideoFrameStatusFailure
};

typedef NS_ENUM(NSUInteger, IMUTLibVideoSourceFailedReason) {
    IMUTLibVideoSourceFailedReasonUnknown = 1,
    IMUTLibVideoSourceFailedFullEncodingQueue = 2,
    IMUTLibVideoSourceFailedNoDataToEncode = 3,
    IMUTLibVideoSourceFailedEncoding = 4,
    IMUTLibVideoSourceFailedNoAvailableMemory = 5
};

// Video frame & bufferPool creation result codes
typedef NS_ENUM(NSUInteger, VFResult) {
    VFResultOK = 0,
    VFResultPixelBufferPoolDrained,
    VFResultVideoFrameBufferPoolDrained,
    VFResultVideoFrameBufferPoolAllocationFailure
};

// Opaque frame buffer pool type
typedef void *VideoFrameBufferPoolRef;

// Opaque frame buffer type
typedef void *VideoFrameBufferRef;

VFResult VideoFrameBufferPoolCreate(unsigned int size, CVPixelBufferPoolRef pixelBufferPool, VideoFrameBufferPoolRef *outBufferPool);

void VideoFrameBufferPoolRelease(VideoFrameBufferRef buffer);

VFResult VideoFrameBufferCreate(VideoFrameBufferRef pool, CMTime frameTime, VideoFrameBufferRef *outBuffer);

void VideoFrameBufferRelease(VideoFrameBufferRef buffer);

CMTime VideoFrameGetCMTime(VideoFrameBufferRef buffer);

CVPixelBufferRef VideoFrameGetPixelBuffer(VideoFrameBufferRef buffer);

// A video recorder suitable for frame polling at a given target framerate
@interface IMUTLibScreenVideoSource : IMUTLibMediaSource

@property(nonatomic, readonly, retain) NSObject <IMUTLibVideoRenderer> *renderer;

+ (instancetype)videoSourceWithRenderer:(NSObject <IMUTLibVideoRenderer> *)renderer targetFrameRate:(unsigned int)maxFrameRate;

@end

@protocol IMUTLibVideoRenderer

// Called when the video source wants a frame to be filled with most current data
- (IMUTLibVideoFrameRenderStatus)renderVideoFrame:(VideoFrameBufferRef)videoFrame withVideoSource:(IMUTLibScreenVideoSource *)videoSource;

// Called when the video source needs to know how to encode the video
- (NSDictionary *)videoSettingsUsingDefaults:(NSMutableDictionary *)videoSettings;

// Called when the video source needs to know how to create pixel buffers
- (NSDictionary *)bufferAttributesUsingDefaults:(NSMutableDictionary *)bufferAttributes;

@optional
// Called when the video source processed a frame. This is called asynchronously.
- (void)videoSource:(IMUTLibScreenVideoSource *)videoSource didProcessFrameAtTime:(CMTime)time;

// Called by the media source when frames were dropped. This is called asynchronously.
- (void)videoSource:(IMUTLibScreenVideoSource *)videoSource droppedFrames:(unsigned long)droppedFrames since:(NSTimeInterval)interval;

@end
