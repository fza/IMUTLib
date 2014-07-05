#import <Foundation/Foundation.h>

#import "IMUTLibMediaSource.h"

// Assuming by testing that one frame takes roughly 2.500 KB in high res, thats 50 MB of memory.
// Plus the memory needed to encode and compress the data though this is fairly efficient and
// hardware accelerated.
#define MAX_ENCODING_QUEUE_SIZE 20
#define MAX_WAIT_FOR_ENCODER_SECS 5.0

@protocol IMUTLibVideoRenderer;

typedef NS_ENUM(NSUInteger, IMUTLibVideoFrameRenderStatus) {
    IMUTLibVideoFrameStatusSuccess = 0,
    IMUTLibVideoFrameStatusFailure = 1
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
    VFResultPixelBufferPoolDrained = 1,
    VFResultVideoFrameBufferPoolDrained = 2,
    VFResultVideoFrameBufferPoolAllocationFailure = 3
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
@interface IMUTLibPollingVideoSource : IMUTLibMediaSource

@property(nonatomic, readonly, retain) NSObject <IMUTLibVideoRenderer> *renderer;

+ (instancetype)videoSourceWithRenderer:(NSObject <IMUTLibVideoRenderer> *)renderer targetFrameRate:(unsigned int)targetFrameRate;

@end

@protocol IMUTLibVideoRenderer

// Called when the video source wants a frame to be filled with most current data
- (IMUTLibVideoFrameRenderStatus)renderVideoFrame:(VideoFrameBufferRef)videoFrame withVideoSource:(IMUTLibPollingVideoSource *)videoSource;

// Called when the video source needs to know how to create pixel buffers
- (NSDictionary *)videoSettingsUsingDefaults:(NSMutableDictionary *)videoSettings;

// Called when the video source needs to know how to create pixel buffers
- (NSDictionary *)bufferAttributesUsingDefaults:(NSMutableDictionary *)bufferAttributes;

@optional
// Called before every recording session to determine the target dispatch queue. If the renderer has it's
// own timer this may be used for synchronization with other tasks.
- (void)videoSource:(IMUTLibPollingVideoSource *)videoSource getTargetDispatchQueue:(dispatch_queue_t *)dispatch_queue;

// Called when the video source failed to process a frame. This is called asynchronously.
- (void)videoSource:(IMUTLibPollingVideoSource *)videoSource failedProcessingFrameAtTime:(CMTime)time reason:(IMUTLibVideoSourceFailedReason)reason;

// Called when the video source processed a frame. This is called asynchronously.
- (void)videoSource:(IMUTLibPollingVideoSource *)videoSource didProcessFrameAtTime:(CMTime)time;

// Called by the media source when frames were dropped. This is called asynchronously.
- (void)videoSource:(IMUTLibPollingVideoSource *)videoSource droppedFrames:(unsigned long)droppedFrames since:(NSTimeInterval)interval;

@end
