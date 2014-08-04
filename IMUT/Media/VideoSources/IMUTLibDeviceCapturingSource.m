#import <UIKit/UIKit.h>
#import "IMUTLibDeviceCapturingSource.h"
#import "IMUTLibFunctions.h"
#import "Macros.h"

@interface IMUTLibDeviceCapturingSource () <AVCaptureVideoDataOutputSampleBufferDelegate>

- (instancetype)initWithWithInputDevice:(AVCaptureDeviceInput *)inputDevice targetFrameRate:(unsigned int)targetFrameRate;

- (NSMutableDictionary *)_defaultVideoSettings;

- (NSMutableDictionary *)_defaultBufferAttributes;

- (void)_calculateFrameRateWithCurrentFrameTime:(CMTime)time;

- (void)_setupCapturingSession;

- (void)_teardownCapturingSession;

- (void)captureSessionError:(NSNotification *)notification;

@end

@implementation IMUTLibDeviceCapturingSource {
    // Frame rate in frames/sec and in fractions of a second
    unsigned int _targetFrameRate;

    // AVFoundation objects
    AVCaptureSession *_captureSession;
    AVCaptureDeviceInput *_deviceInput;
    AVCaptureVideoDataOutput *_videoDataOutput;

    AVAssetWriterInputPixelBufferAdaptor *_pixelBufferAdaptor;

    // Cache information about dropped frames
//    unsigned long _framesDropped;
//    CMTime _framesDroppedReferenceTime;

    // Cached frame time information
    CMTime _previousFrameTime;

    dispatch_queue_t _processingRenderingQueue;

    // Array that contains the timing information of the frames rendered during
    // the previous second. Used to calculate the live framerate.
    NSMutableArray *_previousSecondTimestamps;

}

+ (instancetype)captureSourceWithInputDevice:(AVCaptureDeviceInput *)inputDevice targetFrameRate:(unsigned int)targetFrameRate {
    return [[self alloc] initWithWithInputDevice:inputDevice targetFrameRate:targetFrameRate];
}

- (BOOL)startCapturing {
    @synchronized (self) {
        if ([self isCapturing] || (_captureSession && [_captureSession isRunning])) {
            return NO;
        }

        [self _setupCapturingSession];

        _capturing = YES;
    }

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

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate protocol

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CMTime frameTime = CMTimebaseGetTimeWithTimeScale(
        _currentTimebase,
        (int32_t) _targetFrameRate,
        kCMTimeRoundingMethod_RoundHalfAwayFromZero
    );

    if (frameTime.value <= _previousFrameTime.value) {
        return;
    }

    BOOL accepted = NO;
    if (_writerInput.readyForMoreMediaData) {
        accepted = [_pixelBufferAdaptor appendPixelBuffer:pixelBuffer
                                     withPresentationTime:frameTime];
    }

    [self _calculateFrameRateWithCurrentFrameTime:frameTime];
    _previousFrameTime = _currentSampleTime = _lastSampleTime = frameTime;

    //IMUTLogDebug(@"%lld, %d", frameTime.value, accepted);
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    //CMTime frameTime = CMClockGetTime(_captureSession.masterClock);
    //IMUTLogDebug(@"dropped sample at time: %lld", frameTime.value);
}

#pragma mark Private

- (instancetype)initWithWithInputDevice:(AVCaptureDeviceInput *)inputDevice targetFrameRate:(unsigned int)targetFrameRate {
    if (self = [super init]) {
        _capturing = NO;
        _currentRecordingDuration = _lastRecordingDuration = 0;
        _currentSampleTime = _lastSampleTime = CMTimeMake(0, 0);
        _mediaSourceType = IMUTLibMediaSourceTypeVideo;
        _deviceInput = inputDevice;

        _targetFrameRate = targetFrameRate;
        _currentFrameRate = 0;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(captureSessionError:)
                                                     name:AVCaptureSessionRuntimeErrorNotification
                                                   object:nil];
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
    NSDictionary *videoSettings = [_delegate videoSettingsUsingDefaults:[self _defaultVideoSettings]];
    NSDictionary *bufferAttributes = [_delegate bufferAttributesUsingDefaults:[self _defaultBufferAttributes]];

    // Initialize process vars, which haven't been initialized before
    _previousSecondTimestamps = [NSMutableArray array];

    // Make the processing rendering queue
    _processingRenderingQueue = makeDispatchQueueWithTargetQueue(
        [NSString stringWithFormat:@"capture-source.%p.process", (__bridge void *) self],
        DISPATCH_QUEUE_SERIAL,
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
    );

    // Gather the video settings and bufferPool attributes
    NSString *sessionPreset;
    [_delegate capturingSource:self giveSessionPreset:&sessionPreset];
    if (!sessionPreset) {
        sessionPreset = AVCaptureSessionPresetMedium;
    }

    // Make a new capture session
    _captureSession = [AVCaptureSession new];
    if ([_captureSession canSetSessionPreset:sessionPreset] && [_deviceInput.device supportsAVCaptureSessionPreset:sessionPreset]) {
        _captureSession.sessionPreset = sessionPreset;
    } else {
        NSAssert(false, @"Session \"%@\" preset not supported", sessionPreset);
    }

    // Connect device input
    NSAssert([_captureSession canAddInput:_deviceInput], @"Unable to connect device with capture session.");
    [_captureSession addInput:_deviceInput];

    // Connect video data output
    _videoDataOutput = [AVCaptureVideoDataOutput new];
    _videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    [_videoDataOutput setVideoSettings:bufferAttributes];
    [_videoDataOutput setSampleBufferDelegate:self queue:_processingRenderingQueue];

    // Connect data output
    NSAssert([_captureSession canAddOutput:_videoDataOutput], @"Unable to connect video data output with capture session.");
    [_captureSession addOutput:_videoDataOutput];

    // Setup the writer input
    _writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    _writerInput.expectsMediaDataInRealTime = YES;

    _pixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_writerInput
                                                                                           sourcePixelBufferAttributes:bufferAttributes];

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

    // Inform the writer
    [_writer mediaSourceWillBeginProducingSamples:self];

    [_captureSession startRunning];

    AVCaptureConnection *connection = [_videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    if (connection && [connection isVideoOrientationSupported]) {
        [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    }
}

- (void)_teardownCapturingSession {
    [_captureSession stopRunning];

    // Wait for the encoding queue
    dispatch_group_t dispatchGroup = dispatch_group_create();
    dispatch_group_enter(dispatchGroup);
    dispatch_group_async(dispatchGroup, _processingRenderingQueue, ^{
        dispatch_group_leave(dispatchGroup);
    });

    // Remove capture session
    [_captureSession removeOutput:_videoDataOutput];
    [_captureSession removeInput:_deviceInput];
    _captureSession = nil;

    [_writerInput markAsFinished];

    // Remove video data output connector
    _videoDataOutput = nil;

    // Release the clock
    _currentTimebase = NULL;

    // Swap current and last timing info
    _lastRecordingDuration = _currentRecordingDuration;
    _lastSampleTime = _currentSampleTime;
    _currentRecordingDuration = 0;

    // Relinquish all process variables
    _writerInput = nil;
    _processingRenderingQueue = nil;
    _previousSecondTimestamps = nil;

    [_writer mediaSourceDidStopProducingSamples:self lastSampleTime:_lastSampleTime];

    dispatch_group_wait(dispatchGroup, dispatch_time(DISPATCH_TIME_NOW, (uint64_t) (10.0 * NSEC_PER_SEC)));
}

- (void)captureSessionError:(NSNotification *)notification {
    //NSAssert(false, @"Capture session error occured.");
}

@end
