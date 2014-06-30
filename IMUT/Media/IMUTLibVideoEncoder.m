#import <AVFoundation/AVFoundation.h>
#import <libkern/OSAtomic.h>
#import "IMUTLibVideoEncoder.h"
#import "Macros.h"
#import "IMUTLibTimer.h"
#import "IMUTLibFunctions.h"

@interface IMUTLibVideoEncoder ()

@property(nonatomic, readonly) IMUTLibMediaSourceType mediaSourceType;
@property(nonatomic, readonly, retain) AVAssetWriterInput *writerInput;
@property(nonatomic, readwrite, weak) id <IMUTLibMediaEncoderDelegate> delegate;

- (instancetype)initWithInputDelegate:(id <IMUTLibMediaEncoderVideoDelegate>)inputDelegate;

- (void)runInput;

- (void)runEncode;

// The timing info as it if would be used if there were a new frame to be generated
- (IMUTFrameTimingRef)currentFrameTiming;

- (BOOL)_start;

- (void)_stop;

- (void)informDelegateEncodingFailedAtFrame:(IMUTFrameTimingRef)frameTiming reason:(IMUTLibVideoEncodingFailedReason)reason;

- (void)informDelegateEncodedFrameAt:(IMUTFrameTimingRef)frameTiming;

- (void)informDelegateFramesDropped:(NSUInteger)framesDropped;

@end

@implementation IMUTLibVideoEncoder {
    AVAssetWriterInputPixelBufferAdaptor *_avAssetWriterInputPixelBufferAdaptor;

    IMUTLibTimer *_inputTimer;
    IMUTLibTimer *_encodingTimer;

    unsigned int _targetFramerate;
    double _frameSecondFraction;

    NSTimeInterval _referenceTime;
    IMFrameTimingRef _lastFrameTiming;
    IMInputFrameStackRef _inputFrameStack;
    OSSpinLock _frameTimingLock;

    int32_t _encodingQueueSize;

    unsigned long _framesDropped;
    NSTimeInterval _framesDroppedReferenceTime;

    dispatch_queue_t _runDispatchQueue;
    dispatch_queue_t _delegateNotificationDispatchQueue;

    BOOL _canInformInputDelegateEncodingFailed;
    BOOL _canInformInputDelegateFrameGenerated;
    BOOL _canInformInputDelegateFramesDropped;
}

DESIGNATED_INIT

+ (instancetype)videoEncoderWithInputDelegate:(id <IMUTLibMediaEncoderVideoDelegate>)inputDelegate {
    return [[self alloc] initWithInputDelegate:inputDelegate];
}

#pragma mark IMUTLibMediaEncoder protocol

// If accesses via property notation (encoder.lastFrameTiming) we always return a copy,
// which must be released by the caller. May return NULL if we are not recording.
- (IMUTFrameTimingRef)lastFrameTiming {
    OSSpinLockLock(&_frameTimingLock);
    IMUTFrameTimingRef lastFrameTimingCopy = IMUTCopyFrameTiming(_lastFrameTiming);
    OSSpinLockUnlock(&_frameTimingLock);

    return lastFrameTimingCopy;
}

- (BOOL)start {
    if ([_inputTimer scheduled] && ![_inputTimer paused]) {
        [self stop];

        return NO;
    }

    // Synchronize this call with the timer, if it's running
    __block BOOL status = NO;
    __weak id weakSelf = self;
    dispatch_sync(_runDispatchQueue, ^{
        status = [weakSelf _start];
    });

    return status;
}

- (void)stop {
    if ([_inputTimer paused]) {
        return;
    }

    // Synchronize this call
    __weak id weakSelf = self;
    dispatch_sync(_runDispatchQueue, ^{
        [weakSelf _stop];
    });
}

#pragma mark Private

- (instancetype)initWithInputDelegate:(id <IMUTLibMediaEncoderVideoDelegate>)inputDelegate {
    if (self = [super init]) {
        // Dispatch queues
        _runDispatchQueue = makeDispatchQueue(
            [NSString stringWithFormat:@"video-encoder.%p.run", (__bridge void *) self],
            DISPATCH_QUEUE_SERIAL,
            DISPATCH_QUEUE_PRIORITY_HIGH
        );
        _delegateNotificationDispatchQueue = makeDispatchQueue(
            [NSString stringWithFormat:@"video-encoder.%p.notify", (__bridge void *) self],
            DISPATCH_QUEUE_SERIAL,
            DISPATCH_QUEUE_PRIORITY_LOW
        );

        // The input delegate that is responsible for producing graphic data
        _inputDelegate = inputDelegate;

        // Check the capabilities of the delegate
        _canInformInputDelegateEncodingFailed = [(NSObject *) _inputDelegate respondsToSelector:@selector(encoder:failedEncodingFrameWithTiming:reason:)];
        _canInformInputDelegateFrameGenerated = [(NSObject *) _inputDelegate respondsToSelector:@selector(encoder:didEncodeFrameWithTiming:)];
        _canInformInputDelegateFramesDropped = [(NSObject *) _inputDelegate respondsToSelector:@selector(encoder:droppedFrames:)];

        // This is a video encoder
        _mediaSourceType = IMUTLibMediaSourceTypeVideo;

        // We have no last timing info
        _frameTimingLock = OS_SPINLOCK_INIT;
        _referenceTime = 0;
        _lastFrameTiming = NULL;

        // The target framerate, currently fixed to 35 frames/sec
        _targetFramerate = 35;
        _frameSecondFraction = 1.0 / _targetFramerate;

        // Create the `AVAssetWriterInput` and `AVAssetWriterInputPixelBufferAdaptor` objects
        // that do the heavy lifting
        NSMutableDictionary *bufferAttributes = $MD(@{});
        NSMutableDictionary *videoSettings = $MD(@{
            AVVideoCodecKey : AVVideoCodecH264,
            AVVideoCompressionPropertiesKey : $MD(@{
                AVVideoMaxKeyFrameIntervalKey : @(_targetFramerate)
            })
        });

        if ([(NSObject *) inputDelegate respondsToSelector:@selector(forEncoder:checkVideoSettings:)]) {
            [inputDelegate forEncoder:self checkVideoSettings:videoSettings];
        }

        if ([(NSObject *) inputDelegate respondsToSelector:@selector(forEncoder:checkBufferAttributes:)]) {
            [inputDelegate forEncoder:self checkVideoSettings:bufferAttributes];
        }

        _writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                          outputSettings:videoSettings];
        _writerInput.expectsMediaDataInRealTime = YES;

        _avAssetWriterInputPixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_writerInput
                                                                                                                 sourcePixelBufferAttributes:bufferAttributes];

        // The timers
        _inputTimer = repeatingTimer(_frameSecondFraction, self, @selector(run), _runDispatchQueue, NO);
        _encodingTimer = repeatingTimer(_frameSecondFraction / 2, self, @selector(run), _runDispatchQueue, NO);
    }

    return self;
}

- (void)runInput {
    CVPixelBufferRef pixelBuffer = NULL;
    IMFrameTimingRef preFrameTiming, actualFrameTiming;
    IMUTLibPixelBufferPopulationStatus populationStatus;
    CMTime mediaFrameTime;
    BOOL didAppendFrame;

    // Aquire timing lock at it will change at least two times now
    OSSpinLockLock(&_frameTimingLock);

    if (![self.writerInput isReadyForMoreMediaData]) {
        return;
    }

    preFrameTiming = [self currentFrameTiming];

    // No need to generate a new frame
    if (MAX(preFrameTiming->frameNumber, 1) <= _lastFrameTiming->frameNumber) {
        IMFrameTimingRelease(&preFrameTiming);

        return;
    }

    CVReturn status = CVPixelBufferPoolCreatePixelBuffer(
        kCFAllocatorDefault,
        _avAssetWriterInputPixelBufferAdaptor.pixelBufferPool,
        &pixelBuffer
    );

    if (status == kCVReturnSuccess && pixelBuffer != NULL) {
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);

        // Let the input delegate fill the pixel buffer
        populationStatus = [_inputDelegate forEncoder:self renderFrameInPixelBuffer:pixelBuffer];

        if (populationStatus == IMUTLibPixelBufferPopulationStatusSuccess) {
            // Calculate the timing again as the population could have taken some time
            actualFrameTiming = [self currentFrameTiming];

            // Ensure we are starting with frame number 1. Adjust _referenceTime if necessary
            if (actualFrameTiming->frameNumber == 0) {
                actualFrameTiming->frameNumber = 1;
                actualFrameTiming->frameTime = 0;
                _referenceTime = uptime() - _frameSecondFraction;
            }

            // Append the pixel buffer to the real encoder, possibly hardware accelerated
            mediaFrameTime = CMTimeMake(actualFrameTiming->frameNumber, _targetFramerate);
            didAppendFrame = [_avAssetWriterInputPixelBufferAdaptor appendPixelBuffer:pixelBuffer
                                                                      withPresentationTime:mediaFrameTime];

            // Process result
            if (!didAppendFrame) {
                if (_canInformInputDelegateEncodingFailed) {
                    [self informDelegateEncodingFailedAtFrame:actualFrameTiming
                                                       reason:IMUTLibVideoEncodingFailedInternal];
                }
            } else if (_canInformInputDelegateFrameGenerated) {
                // Inform the delegate
                [self informDelegateEncodedFrameAt:actualFrameTiming];
            }

            // Calculate and report dropped frames every 3 seconds
            if (_canInformInputDelegateFramesDropped) {
                if (_framesDroppedReferenceTime == -1) {
                    _framesDroppedReferenceTime = _referenceTime;
                }

                // _framesDropped should ideally stay at 0
                _framesDropped += actualFrameTiming->frameNumber - _lastFrameTiming->frameNumber - (didAppendFrame ? 1 : 0);
                if (_framesDropped > 0 && uptime() - _framesDroppedReferenceTime > 3) {
                    [self informDelegateFramesDropped:_framesDropped];
                    _framesDropped = 0;
                    _framesDroppedReferenceTime = uptime();
                }
            }

            // Copy and store frame timing
            IMUTFrameTimingRelease(&_lastFrameTiming);
            _lastFrameTiming = actualFrameTiming;
        }

        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    }

    // Can release timing lock
    OSSpinLockUnlock(&_frameTimingLock);

    CVPixelBufferRelease(pixelBuffer);
    IMUTFrameTimingRelease(&preFrameTiming);
}

// The timer makes sure that this method is never executed in parallel
- (void)runEncode {

}

// Called exclusively by `run`
- (IMUTFrameTimingRef)currentFrameTiming {
    if (_lastFrameTiming == NULL) {
        return IMUTMakeFrameTiming(0, 0);
    }

    double nowTime = uptime();
    NSTimeInterval frameTime = nowTime - _referenceTime;
    unsigned long frameNumber = _lastFrameTiming->frameNumber != 0 ? (unsigned long) round(frameTime / _frameSecondFraction) : 0;

    return IMUTMakeFrameTiming(frameNumber, frameTime);
}

- (BOOL)_start {
    // New frame stack


    // Initialize timing with reference time
    _referenceTime = uptime();
    _lastFrameTiming = [self currentFrameTiming];

    // Initialize dropped frames counter
    _framesDropped = 0;
    _framesDroppedReferenceTime = -1;

    // Initialize the encoding queue size, i.e. the backlog of frames that wait for being encoded.
    _encodingQueueSize = 0;

    // Tell the delegate that we are about to start encoding
    [_delegate encoderWillBeginProducingStream];

    // Generate first frame and resume the timers
    [self runInput];
    [_inputTimer resume];
    [_encodingTimer resume];

    // TODO: Currently always returning YES here, but more specific pre-checks need to be implemented.
    return YES;
}

- (void)_stop {
    // Stop the timer
    [_inputTimer pause];
    [_encodingTimer pause];

    // Tell the delegate that we stopped encoding
    [_delegate encoderStoppedProducingStream];

    // Invalidate _lastFrameTiming and referene time
    IMUTFrameTimingRelease(&_lastFrameTiming);
    _lastFrameTiming = NULL;
    _referenceTime = 0;
}

- (void)informDelegateEncodingFailedAtFrame:(IMUTFrameTimingRef)frameTiming reason:(IMUTLibVideoEncodingFailedReason)reason {
    __weak id weakInputDelegate = _inputDelegate;
    frameTiming = IMUTCopyFrameTiming(frameTiming);
    dispatch_async(_delegateNotificationDispatchQueue, ^{
        [weakInputDelegate encoder:self failedEncodingFrameWithTiming:frameTiming reason:reason];
        IMUTFrameTimingRelease(&frameTiming);
    });
}

- (void)informDelegateEncodedFrameAt:(IMUTFrameTimingRef)frameTiming {
    __weak id weakInputDelegate = _inputDelegate;
    frameTiming = IMUTCopyFrameTiming(frameTiming);
    dispatch_async(_delegateNotificationDispatchQueue, ^{
        [weakInputDelegate encoder:self didEncodeFrameWithTiming:frameTiming];
        IMUTFrameTimingRelease(&frameTiming);
    });
}

- (void)informDelegateFramesDropped:(NSUInteger)framesDropped {
    __weak id weakInputDelegate = _inputDelegate;
    dispatch_async(_delegateNotificationDispatchQueue, ^{
        [weakInputDelegate encoder:self droppedFrames:framesDropped];
    });
}

@end
