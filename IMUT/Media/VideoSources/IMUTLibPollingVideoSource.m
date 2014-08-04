#import <UIKit/UIKit.h>
#import <libkern/OSAtomic.h>
#import <CoreMedia/CoreMedia.h>

#import "IMUTLibPollingVideoSource.h"
#import "IMUTLibFunctions.h"
#import "Macros.h"
#import "IMUTLibTimer.h"

#define VIDEO_SOURCE_DEBUG 0

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

@interface IMUTLibPollingVideoSource ()

@property(nonatomic, readwrite, assign) unsigned int targetFrameRate;

@property(nonatomic, readwrite, retain) NSObject <IMUTLibVideoRenderer> *renderer;

- (instancetype)initWithRenderer:(NSObject <IMUTLibVideoRenderer> *)renderer targetFrameRate:(unsigned int)targetFrameRate;

- (NSMutableDictionary *)_defaultVideoSettings;

- (NSMutableDictionary *)_defaultBufferAttributes;

- (void)_calculateFrameRateWithCurrentFrameTime:(CMTime)time;

- (void)_setupCapturingSession;

- (void)_teardownCapturingSession;

- (void)_render;

- (void)_encode;

@end

@implementation IMUTLibPollingVideoSource {
    // Cache information about the renderer's implementation of optional protocol methods
    BOOL _canAskRendererForTargetDispatchQueue;
    BOOL _canInformRendererProcessingFailed;
    BOOL _canInformRendererFrameProcessed;
    BOOL _canInformRendererFramesDropped;

    // Flag indicating if the post-initialization had been done after rendering the
    // first frame
    BOOL _processedFirstFrame;

    // Frame rate in frames/sec and in fractions of a second
    unsigned int _targetFrameRate;
    double _frameSecondFraction;

    // Cache information about dropped frames
    unsigned long _framesDropped;
    CMTime _framesDroppedReferenceTime;

    // Cached frame time information
    CMTime _previousFrameTime;

    // The video frame bufferPool
    VideoFrameBufferRef _videoFrameBufferPool;

    // Array that contains the timing information of the frames rendered during
    // the previous second. Used to calculate the live framerate.
    NSMutableArray *_previousSecondTimestamps;

    // The dispatch queue of the rendering system
    dispatch_queue_t _renderingDispatchQueue;
    IMUTLibTimer *_renderingTimer;

    // The encoding subsystem
    dispatch_queue_t _encodingDispatchQueue;
    NSMutableArray *_encodingQueue;
    OSSpinLock _encodingQueueLock;
    int32_t _encodingQueueSize;
    IMUTLibTimer *_encodingTimer;

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

        NSAssert(self.renderer, @"A polling media source needs a renderer, none set.");

        [self _setupCapturingSession];

        _capturing = YES;
    }

    // Always return yes for now, probably a few more checks are needed
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
    NSAssert(renderer, @"Polling video source expects a renderer at initialization.");

    if (self = [super init]) {
        _capturing = NO;
        _currentRecordingDuration = _lastRecordingDuration = 0;
        _currentSampleTime = _lastSampleTime = CMTimeMake(0, 0);
        _mediaSourceType = IMUTLibMediaSourceTypeVideo;
        _renderer = renderer;

        _targetFrameRate = targetFrameRate;
        _frameSecondFraction = 1.0 / targetFrameRate;
        _currentFrameRate = 0;
        _encodingQueueLock = OS_SPINLOCK_INIT;

        _canAskRendererForTargetDispatchQueue = [renderer respondsToSelector:@selector(videoSource:getTargetDispatchQueue:)];
        _canInformRendererProcessingFailed = [renderer respondsToSelector:@selector(videoSource:failedProcessingFrameAtTime:reason:)];
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

- (void)_calculateFrameRateWithCurrentFrameTime:(CMTime)time; {
    [_previousSecondTimestamps addObject:[NSValue valueWithCMTime:time]];

    CMTime oneSecond = CMTimeMake(1, 1);
    CMTime oneSecondAgo = CMTimeSubtract(time, oneSecond);

    while (CMTIME_COMPARE_INLINE([[_previousSecondTimestamps objectAtIndex:0] CMTimeValue], <=, oneSecondAgo)) {
        [_previousSecondTimestamps removeObjectAtIndex:0];
    }

    _currentFrameRate = (_currentFrameRate + [_previousSecondTimestamps count]) / 2.0;
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

    // Setup the recorder dispatcher
    dispatch_queue_t renderingTargetQueue = NULL;
    if (_canAskRendererForTargetDispatchQueue) {
        [_renderer videoSource:self getTargetDispatchQueue:&renderingTargetQueue];
    }
    _renderingDispatchQueue = makeDispatchQueueWithTargetQueue(
        [NSString stringWithFormat:@"video-source.%p.render", (__bridge void *) self],
        DISPATCH_QUEUE_SERIAL,
        renderingTargetQueue != NULL ? renderingTargetQueue : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
    );

    // Setup the encoding dispatcher
    _encodingDispatchQueue = makeDispatchQueue(
        [NSString stringWithFormat:@"video-source.%p.run", (__bridge void *) self],
        DISPATCH_QUEUE_SERIAL,
        DISPATCH_QUEUE_PRIORITY_DEFAULT
    );

    // Setup the rendering timer
    _renderingTimer = makeRepeatingTimer(_frameSecondFraction, self, @selector(_render), _renderingDispatchQueue, NO);
    _renderingTimer.tolerance = 10 * 1000 / NSEC_PER_SEC; // System times are given in nanoseconds

    // Setup the encoding timer
    _encodingTimer = makeRepeatingTimer(_frameSecondFraction, self, @selector(_encode), _encodingDispatchQueue, NO);
    _encodingTimer.tolerance = 100 * 1000 / NSEC_PER_SEC;

    // Setup encoding queue
    _encodingQueueSize = 0;
    _encodingQueue = [NSMutableArray arrayWithCapacity:MAX_ENCODING_QUEUE_SIZE];

    // Setup the master timebase, which is backed by `mach_absolute_time`, the kernel's processor clock
    OSStatus timebaseCreateStatus = CMTimebaseCreateWithMasterClock(
        kCFAllocatorDefault,
        CMClockGetHostTimeClock(),
        &_currentTimebase
    );

    NSAssert(timebaseCreateStatus == 0, @"Could not create timebase.");

    // Initialize the timebase
    CMTime now = CMTimeMake(0, 1000 * 1000);
    CMTimebaseSetTime(_currentTimebase, now);
    CMTimebaseSetRate(_currentTimebase, 1.0);

    // Initialize process vars, which haven't been initialized before
    _processedFirstFrame = NO;
    _previousSecondTimestamps = [NSMutableArray array];

    // Schedule the timers
    [_renderingTimer resume];
    [_encodingTimer resumeAfter:_frameSecondFraction * 2.0];

    // Inform the writer
    [_writer mediaSourceWillBeginProducingSamples:self];

    // Setup the video frame bufferPool
    VFResult result = VideoFrameBufferPoolCreate(
        MAX_ENCODING_QUEUE_SIZE,
        _pixelBufferAdaptor.pixelBufferPool,
        &_videoFrameBufferPool
    );

    NSAssert(result == 0, @"Could not allocate video frame bufferPool pool");
}

- (void)_teardownCapturingSession {
    // Invalidate the rendering timer after one last frame
    [_renderingTimer runOutAndInvalidateWaitUntilDone:YES];

    // Wait for the encoding queue
    dispatch_group_t dispatchGroup = dispatch_group_create();
    dispatch_group_enter(dispatchGroup);
    [_encodingTimer setInvaliationHandler:^{
        dispatch_group_leave(dispatchGroup);
    }];
    [_encodingTimer runOutAndInvalidateWaitUntilDone:YES];

    [_writerInput markAsFinished];

    // Release the clock
    _currentTimebase = NULL;

    // Release video frame bufferPool
    VideoFrameBufferPoolRelease(_videoFrameBufferPool);
    _videoFrameBufferPool = NULL;

    // Swap current and last timing info
    _lastRecordingDuration = _currentRecordingDuration;
    _lastSampleTime = _currentSampleTime;
    _currentRecordingDuration = 0;

    // Relinquish all process variables
    _renderingTimer = nil;
    _renderingDispatchQueue = nil;
    _writerInput = nil;
    _pixelBufferAdaptor = nil;
    _processedFirstFrame = NO;
    _previousSecondTimestamps = nil;
    _framesDropped = 0;
    _framesDroppedReferenceTime = _currentSampleTime = _previousFrameTime = CMTimeMake(0, 0);

    [_writer mediaSourceDidStopProducingSamples:self lastSampleTime:_lastSampleTime];

    dispatch_group_wait(dispatchGroup, dispatch_time(DISPATCH_TIME_NOW, (int64_t) (MAX_WAIT_FOR_ENCODER_SECS * NSEC_PER_SEC)));
}

- (void)_render {
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
        // Set actual timebase
        frameTime = CMTimeMake(1, _targetFrameRate);
        CMTime startTime = CMTimeMake(0, _targetFrameRate);
        CMTimebaseSetTime(_currentTimebase, startTime);
        _previousFrameTime = _framesDroppedReferenceTime = frameTime;
    } else if (frameTime.value <= _previousFrameTime.value) {
        // Already have a frame for this timestamp
        return;
    }

    // Can be push new data to the encoding queue?
    if (_encodingQueueSize > MAX_ENCODING_QUEUE_SIZE) {
        if (_canInformRendererProcessingFailed) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_renderer videoSource:self
           failedProcessingFrameAtTime:frameTime
                                reason:IMUTLibVideoSourceFailedFullEncodingQueue];
            });
        }

        return;
    }

    // Calculate framerate
    [self _calculateFrameRateWithCurrentFrameTime:frameTime];

    // Log the current framerate
#if VIDEO_SOURCE_DEBUG
    IMUTLogDebug(@"frame: %qi -- framerate: %.5f -- time: %.5f", frameTime.value, _currentFrameRate, CMTimeGetSeconds(frameTime));
#endif

    // Allocate new video frame
    VFResult result = VideoFrameBufferCreate(_videoFrameBufferPool, frameTime, &videoFrame);

    if (result == VFResultOK) {
        // Delegate the rendering, the renderer should fill the bufferPool
        renderingStatus = [_renderer renderVideoFrame:videoFrame withVideoSource:self];

        if (renderingStatus == IMUTLibVideoFrameStatusSuccess) {
            // Increment the encoding queue size amd enqueue the video frame
            OSSpinLockLock(&_encodingQueueLock);
            [_encodingQueue addObject:[NSValue valueWithPointer:videoFrame]];
            _encodingQueueSize++;
            OSSpinLockUnlock(&_encodingQueueLock);
        } else {
#if VIDEO_SOURCE_DEBUG
            IMUTLogDebug(@"Rendering failed for frame: %qi", frameTime.value);
#endif

            VideoFrameBufferRelease(videoFrame);

            if (_canInformRendererProcessingFailed) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_renderer videoSource:self
               failedProcessingFrameAtTime:frameTime
                                    reason:IMUTLibVideoSourceFailedNoDataToEncode];
                });
            }
        }

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
    } else if (_canInformRendererProcessingFailed) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_renderer videoSource:self
       failedProcessingFrameAtTime:frameTime
                            reason:IMUTLibVideoSourceFailedNoAvailableMemory];
        });
    }
}

- (void)_encode {
    if (_encodingQueueSize == 0) {
        return;
    }

    OSSpinLockLock(&_encodingQueueLock);
    VideoFrameBufferRef videoFrame = [(NSValue *) [_encodingQueue objectAtIndex:0] pointerValue];
    [_encodingQueue removeObjectAtIndex:0];
    _encodingQueueSize--;
    OSSpinLockUnlock(&_encodingQueueLock);

    CMTime frameTime = VideoFrameGetCMTime(videoFrame);

#if VIDEO_SOURCE_DEBUG
    IMUTLogDebug(@"Encoding frame: %qi", frameTime.value);
#endif

    BOOL result = [_pixelBufferAdaptor appendPixelBuffer:VideoFrameGetPixelBuffer(videoFrame)
                                    withPresentationTime:frameTime];

    if (!result && _canInformRendererProcessingFailed) {
#if VIDEO_SOURCE_DEBUG
        IMUTLogDebug(@"Failed encoding frame: %qi", frameTime.value);
#endif

        dispatch_async(dispatch_get_main_queue(), ^{
            [_renderer videoSource:self
       failedProcessingFrameAtTime:frameTime
                            reason:IMUTLibVideoSourceFailedEncoding];
        });
    } else if (_canInformRendererFrameProcessed) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_renderer videoSource:self didProcessFrameAtTime:frameTime];
        });
    }

    // Release video frame
    VideoFrameBufferRelease(videoFrame);
}

@end
