#import <libkern/OSAtomic.h>
#import <CoreMedia/CoreMedia.h>

#import "IMUTLibScreenVideoSource.h"
#import "IMUTLibMediaSource+FrameRateCalculation.h"
#import "IMUTLibFunctions.h"
#import "Macros.h"
#import "IMUTLibTimer.h"

typedef struct VideoFrameBuffer {
    CMTime frameTime;
    CVPixelBufferRef pixelBuffer;
    VideoFrameBufferPoolRef const bufferPool;
} VideoFrameBuffer;

typedef VideoFrameBuffer *VideoFrameBufferRefReal;

typedef struct VideoFrameBufferPool {
    CVPixelBufferPoolRef pixelBufferPool;
    unsigned int size;
    unsigned int used;
    OSSpinLock lock;
    VideoFrameBuffer **refs;
    VideoFrameBuffer *data;
} VideoFrameBufferPool;

typedef VideoFrameBufferPool *VideoFrameBufferPoolRefReal;

VFResult VideoFrameBufferPoolCreate(unsigned int size, CVPixelBufferPoolRef pixelBufferPool, VideoFrameBufferPoolRef *outBufferPool) {
    if (pixelBufferPool == NULL) {
        return VFResultVideoFrameBufferPoolAllocationFailure;
    }

    size_t memSize = sizeof(VideoFrameBufferPool) + sizeof(VideoFrameBuffer *) * size + sizeof(VideoFrameBuffer) * size;
    VideoFrameBufferPoolRefReal pool = (VideoFrameBufferPool *) CFAllocatorAllocate(kCFAllocatorDefault, memSize, 0);
    memset(pool, 0, memSize);

    *pool = (VideoFrameBufferPool) {
        .pixelBufferPool = pixelBufferPool,
        .size = size,
        .used = 0,
        .lock = OS_SPINLOCK_INIT,
        .refs = (VideoFrameBufferRefReal *) (pool + 1),
    };

    pool->data = (VideoFrameBuffer *) (pool->refs + size);

    *outBufferPool = pool;

    return VFResultOK;
}

void VideoFrameBufferPoolRelease(VideoFrameBufferRef buffer) {
    if (buffer != NULL) {
        CFAllocatorDeallocate(kCFAllocatorDefault, buffer);
    }
}

VFResult VideoFrameBufferCreate(VideoFrameBufferPoolRef pool, CMTime frameTime, VideoFrameBufferRef *outBuffer) {
    if (pool == NULL) {
        return VFResultVideoFrameBufferPoolAllocationFailure;
    }

    VideoFrameBufferPoolRefReal poolReal = (VideoFrameBufferPoolRefReal) pool;
    unsigned int allocatePosition;
    BOOL canAllocate = NO;
    VideoFrameBufferRefReal videoFrameBuffer = NULL;

    OSSpinLockLock(&poolReal->lock);
    if (poolReal->used == poolReal->size) {
        return VFResultVideoFrameBufferPoolDrained;
    }

    for (allocatePosition = 0; allocatePosition < poolReal->size; allocatePosition++) {
        if (poolReal->refs[allocatePosition] == NULL) {
            canAllocate = YES;
            break;
        }
    }

    if (!canAllocate) {
        return VFResultVideoFrameBufferPoolDrained;
    }

    CVPixelBufferRef pixelBuffer;
    CVReturn pixelBufferAllocationStatus = CVPixelBufferPoolCreatePixelBuffer(
        kCFAllocatorDefault,
        poolReal->pixelBufferPool,
        &pixelBuffer
    );

    if (pixelBufferAllocationStatus != kCVReturnSuccess || pixelBuffer == NULL) {
        return VFResultPixelBufferPoolDrained;
    }

    CVPixelBufferLockBaseAddress(pixelBuffer, 0);

    videoFrameBuffer = &poolReal->data[allocatePosition];
    *videoFrameBuffer = (VideoFrameBuffer) {
        .frameTime = frameTime,
        .pixelBuffer = pixelBuffer,
        .bufferPool = poolReal
    };

    poolReal->refs[allocatePosition] = videoFrameBuffer;
    poolReal->used++;
    OSSpinLockUnlock(&poolReal->lock);

    *outBuffer = (VideoFrameBufferRef) videoFrameBuffer;

    return VFResultOK;
}

void VideoFrameBufferRelease(VideoFrameBufferRef buffer) {
    if (buffer == NULL) {
        return;
    }

    VideoFrameBufferRefReal bufferReal = (VideoFrameBufferRefReal) buffer;
    VideoFrameBufferPoolRefReal poolReal = bufferReal->bufferPool;

    if (poolReal == NULL) {
        return;
    }

    OSSpinLockLock(&poolReal->lock);
    unsigned int allocatePosition;

    CVPixelBufferUnlockBaseAddress(bufferReal->pixelBuffer, 0);
    CVPixelBufferRelease(bufferReal->pixelBuffer);

    // TODO Optimize
    for (allocatePosition = 0; allocatePosition < poolReal->size; allocatePosition++) {
        if (buffer == poolReal->refs[allocatePosition]) {
            poolReal->refs[allocatePosition] = NULL;
            break;
        }
    }

    poolReal->used--;
    OSSpinLockUnlock(&poolReal->lock);
}

CMTime VideoFrameGetCMTime(VideoFrameBufferRef buffer) {
    if (buffer != NULL) {
        VideoFrameBufferRefReal bufferReal = (VideoFrameBufferRefReal) buffer;

        return bufferReal->frameTime;
    }

    return CMTimeMake(0, 0);
}

CVPixelBufferRef VideoFrameGetPixelBuffer(VideoFrameBufferRef buffer) {
    if (buffer != NULL) {
        VideoFrameBufferRefReal bufferReal = (VideoFrameBufferRefReal) buffer;

        return bufferReal->pixelBuffer;
    }

    return NULL;
}

@interface IMUTLibScreenVideoSource ()

@property(nonatomic, readwrite, retain) NSObject <IMUTLibVideoRenderer> *renderer;

- (instancetype)initWithRenderer:(NSObject <IMUTLibVideoRenderer> *)renderer targetFrameRate:(unsigned int)targetFrameRate;

- (NSMutableDictionary *)_defaultVideoSettings;

- (NSMutableDictionary *)_defaultBufferAttributes;

- (void)_setupCapturingSession;

- (void)_teardownCapturingSession;

- (void)_initRendering;

- (void)_render;

@end

@implementation IMUTLibScreenVideoSource {
    // Cache information about the renderer's implementation of optional protocol methods
    BOOL _canInformRendererFrameProcessed;
    BOOL _canInformRendererFramesDropped;

    // The rendering thread providing the runloop to use
    NSThread *_renderingThread;

    // Wether the rendering should stop now
    BOOL _renderingShouldStop;

    // The dispatch group used to synchronize stop of rendering and encoding
    dispatch_group_t _dispatchGroupStop;

    // Flag indicating if the post-initialization had been done after rendering the first frame
    BOOL _processedFirstFrame;

    // Frame rate in frames/sec and in fractions of a second
    unsigned int _targetFrameRate;

    // The display link
    CADisplayLink *_displayLink;

    // Cache information about dropped frames
    unsigned long _framesDropped;
    CMTime _framesDroppedReferenceTime;

    // Cached frame time information
    CMTime _previousFrameTime;

    // The video frame buffer pool
    VideoFrameBufferRef _videoFrameBufferPool;

    // The pixel bufferPool adaptor that shifts pixel buffers into the
    // asset writer input object.
    AVAssetWriterInputPixelBufferAdaptor *_pixelBufferAdaptor;
}

@dynamic currentFrameRate;
@dynamic currentRecordingDuration;

+ (instancetype)videoSourceWithRenderer:(NSObject <IMUTLibVideoRenderer> *)renderer targetFrameRate:(unsigned int)targetFrameRate {
    return [[self alloc] initWithRenderer:renderer targetFrameRate:targetFrameRate];
}

- (BOOL)startCapturing {
    @synchronized (self) {
        if ([self isCapturing]) {
            return NO;
        }

        [self _setupCapturingSession];

        _capturing = YES;
    }

    // Always return yes for now, probably need a few more checks here
    return YES;
}

- (void)stopCapturing {
    @synchronized (self) {
        if (![self isCapturing]) {
            return;
        }

        [self _teardownCapturingSession];

        _capturing = NO;
    }
}

- (void)setWriter:(IMUTLibMediaWriter *)writer {
    @synchronized (self) {
        NSAssert(![self isCapturing], @"Cannot set a new writer while data capturing is in progress.");

        _writer = writer;
    }
}

#pragma mark Private

- (instancetype)initWithRenderer:(NSObject <IMUTLibVideoRenderer> *)renderer targetFrameRate:(unsigned int)targetFrameRate {
    if (self = [super init]) {
        _capturing = NO;
        _currentRecordingDuration = _lastRecordingDuration = 0;
        _currentSampleTime = _lastSampleTime = CMTimeMake(0, 0);
        _mediaSourceType = IMUTLibMediaSourceTypeVideo;

        _renderer = renderer;

        _targetFrameRate = targetFrameRate;
        _currentFrameRate = 0;

        _canInformRendererFrameProcessed = [renderer respondsToSelector:@selector(videoSource:didProcessFrameAtTime:)];
        _canInformRendererFramesDropped = [renderer respondsToSelector:@selector(videoSource:droppedFrames:since:)];
    }

    return self;
}

- (NSMutableDictionary *)_defaultVideoSettings {
    return $MD(@{
        AVVideoCodecKey : AVVideoCodecH264,
        AVVideoCompressionPropertiesKey : $MD(@{
            AVVideoMaxKeyFrameIntervalKey : @(_targetFrameRate * 10)
        })
    });
}

- (NSMutableDictionary *)_defaultBufferAttributes {
    return $MD(@{
        (__bridge NSString *) kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)
    });
}

- (void)_setupCapturingSession {
    // Gather the video settings and bufferPool attributes
    NSDictionary *videoSettings = [_renderer videoSettingsUsingDefaults:[self _defaultVideoSettings]];
    NSDictionary *bufferAttributes = [_renderer bufferAttributesUsingDefaults:[self _defaultBufferAttributes]];

    // Setup the writer input
    _writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    _writerInput.expectsMediaDataInRealTime = YES;

    // Setup the pixel bufferPool adaptor which transforms pixel buffers to media samples
    _pixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_writerInput
                                                                                           sourcePixelBufferAttributes:bufferAttributes];

    // Setup the master timebase, which is backed by `mach_absolute_time`, the kernel's processor clock
    CMTimebaseCreateWithMasterClock(
        kCFAllocatorDefault,
        CMClockGetHostTimeClock(),
        &_currentTimebase
    );

    // Initialize the timebase
    CMTime now = CMTimeMake(0, 1000 * 1000);
    CMTimebaseSetTime(_currentTimebase, now);
    CMTimebaseSetRate(_currentTimebase, 1.0);

    // Initialize some more process vars
    _processedFirstFrame = NO;
    _renderingShouldStop = NO;
    _previousSecTimestamps = [NSMutableArray array];

    // Inform the writer
    [_writer mediaSourceWillBeginProducingSamples:self];

    // Setup the video frame buffer pool with a length of 5 (approx. 7.5 MB of memory)
#ifdef DEBUG
    VFResult result = VideoFrameBufferPoolCreate(20, _pixelBufferAdaptor.pixelBufferPool, &_videoFrameBufferPool);
    NSAssert(result == 0, @"Could not allocate video frame buffer pool");
#else
    VideoFrameBufferPoolCreate(20, _pixelBufferAdaptor.pixelBufferPool, &_videoFrameBufferPool);
#endif

    // Create the rendering thread
    _renderingThread = [[NSThread alloc] initWithTarget:self
                                               selector:@selector(_initRendering)
                                                 object:nil];
    [_renderingThread start];
}

- (void)_teardownCapturingSession {
    // Wait for the rendering to stop...
    _dispatchGroupStop = dispatch_group_create();
    dispatch_group_enter(_dispatchGroupStop);
    _renderingShouldStop = YES;
    dispatch_group_wait(_dispatchGroupStop, DISPATCH_TIME_FOREVER); //dispatch_time(DISPATCH_TIME_NOW, (int64_t) (MAX_WAIT_TO_STOP_SECS * NSEC_PER_SEC)));
    _dispatchGroupStop = nil;

    // Tell the encoder that there is no more data to come
    [_writerInput markAsFinished];

    // Release the clock
    _currentTimebase = NULL;

    // Swap current and last timing info
    _lastRecordingDuration = _currentRecordingDuration;
    _lastSampleTime = _currentSampleTime;
    _currentRecordingDuration = 0;

    // Reset process variables
    _writerInput = nil;
    _pixelBufferAdaptor = nil;
    _processedFirstFrame = NO;
    _renderingShouldStop = NO;
    _previousSecTimestamps = nil;
    _framesDropped = 0;
    _framesDroppedReferenceTime = _currentSampleTime = _previousFrameTime = CMTimeMake(0, 0);

    // Tell the writer to finalize the media container
    [_writer mediaSourceDidStopProducingSamples:self lastSampleTime:_lastSampleTime];

    // Release the video frame buffer pool
    VideoFrameBufferPoolRelease(_videoFrameBufferPool);
    _videoFrameBufferPool = NULL;

    // Don't need the thread instance any longer
    _renderingThread = nil;

    // The live computed frame rate has no meaning any longer
    [self _resetCalculatedFrameRate];
}

// Rendering thread entry point
// Having a separate rendering thread, which is not the main thread, allows the UI to run smoothly
// as it is never blocked, but allows us to intercept the underlying UI drawing mechanism by
// having the _render method being called in between the UI drawing instances. However, with a high
// frame rate it may still affect the UI rendering -- although it's rendered on the view layer level
// it may not be processed/consumed by the GPU at the same rate.
- (void)_initRendering {
    // Setup the display link (= "the timer" that triggers the frame rendering)
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(_render)];
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

    // Invoke the runloop
    [[NSRunLoop currentRunLoop] run];

    if (_dispatchGroupStop) {
        dispatch_group_leave(_dispatchGroupStop);
    }
}

#define MAX_FPS 60
#define MAX_FRAME_INTERVAL 6 // set min fps = 10

- (void)_render {
    if (_renderingShouldStop) {
        [_displayLink invalidate];

        return;
    }

    CMTime frameTime;
    VideoFrameBufferRef videoFrame;
    IMUTLibVideoFrameRenderStatus renderingStatus;

    // Get the exact current time tied to the target framerate
    frameTime = CMTimebaseGetTimeWithTimeScale(
        _currentTimebase,
        (int32_t) _targetFrameRate,
        kCMTimeRoundingMethod_RoundHalfAwayFromZero
    );

    if (!_processedFirstFrame) {
        // Wait 0.25sec until we start capturing the screen to prevent initial almost-black frames
        CMTime initialTime = CMTimebaseGetTime(_currentTimebase);
        if (initialTime.value < 25 * initialTime.timescale / 100) {
            return;
        }

        // Calculate usable framerate
        double refreshRate = _displayLink.duration; // this is normally 1/60
        double checkFramesPerSec;
        int frameInterval = 1;
        for (; frameInterval <= MAX_FRAME_INTERVAL; frameInterval++) {
            checkFramesPerSec = MAX_FPS / frameInterval;
            // The actual frame interval cannot be faster than the refresh rate, but must be smaller
            // than or equal the desired target frame rate.
            if (((int) ((1.0 / checkFramesPerSec) * 1000) >= (int) (refreshRate * 1000)) && checkFramesPerSec <= _targetFrameRate) {
                break;
            }
        }
        _displayLink.frameInterval = MIN(MAX_FRAME_INTERVAL, frameInterval);

        // Set actual frame timebase
        frameTime = CMTimeMake(1, _targetFrameRate);
        CMTime startTime = CMTimeMake(0, _targetFrameRate);
        CMTimebaseSetTime(_currentTimebase, startTime);
        _previousFrameTime = _framesDroppedReferenceTime = frameTime;
    } else if (frameTime.value <= _previousFrameTime.value) {
        // Already have a frame for this timestamp
        return;
    }

    // Calculate framerate
    [self _calculateFrameRateWithCurrentFrameTime:frameTime];

    // Allocate new video frame
    VFResult result = VideoFrameBufferCreate(_videoFrameBufferPool, frameTime, &videoFrame);

    if (result == VFResultOK) {
        // Delegate the rendering
        renderingStatus = [_renderer renderVideoFrame:videoFrame withVideoSource:self];

        if (renderingStatus == IMUTLibVideoFrameStatusSuccess) {
            [_pixelBufferAdaptor appendPixelBuffer:VideoFrameGetPixelBuffer(videoFrame) withPresentationTime:frameTime];

            if (_canInformRendererFrameProcessed) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_renderer videoSource:self didProcessFrameAtTime:frameTime];
                });
            }
        }

        VideoFrameBufferRelease(videoFrame);

        if (_canInformRendererFramesDropped) {
            _framesDropped += CMTimeAbsoluteValue(CMTimeSubtract(frameTime, _previousFrameTime)).value;
            Float64 timePassed = CMTimeGetSeconds(CMTimeSubtract(frameTime, _framesDroppedReferenceTime));
            if (_framesDropped > 0 && timePassed >= 3) {
                unsigned long framesDropped = _framesDropped;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_renderer videoSource:self droppedFrames:framesDropped since:timePassed];
                });

                _framesDropped = 0;
            }
            _framesDroppedReferenceTime = frameTime;
        }

        _processedFirstFrame = YES;
        _previousFrameTime = _currentSampleTime = frameTime;
        _currentRecordingDuration = CMTimeGetSeconds(frameTime);
    }
}

@end
