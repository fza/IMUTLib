#import <sys/time.h>
#import <AVFoundation/AVFoundation.h>
#import "IMUTLibMediaFrameBasedVideoEncoder.h"
#import "IMUTLibTimer.h"
#import "IMUTLibFunctions.h"
#import "Macros.h"

static int mediaSourceId;

@interface IMUTLibMediaFrameBasedVideoEncoder ()

@property(nonatomic, readwrite, assign) IMUTLibMediaSourceType mediaSourceType;
@property(nonatomic, readwrite, retain) AVAssetWriterInput *writerInput;
@property(nonatomic, readwrite, assign) BOOL stopped;
@property(nonatomic, readwrite, retain) NSDate *dateOfFirstFrame;
@property(nonatomic, readwrite, weak) id <IMUTLibMediaEncoderVideoDelegate> inputDelegate;

- (instancetype)initWithInputDelegate:(id <IMUTLibMediaEncoderVideoDelegate>)inputDelegate andName:(NSString *)name;

@end

@implementation IMUTLibMediaFrameBasedVideoEncoder {
    AVAssetWriterInputPixelBufferAdaptor *_avAssetWriterInputPixelBufferAdaptor;
    dispatch_queue_t _timerDispatchQueue;
    int64_t _lastFrameNumber;
    int _targetFramerate;
    double _frameSecondFraction;
    struct timeval _baseTime;
    IMUTLibTimer *_timer;
    BOOL _didWriteFirstFrame;
    NSString *_sourceName;
    NSUInteger _framesDroppedCurrent;
    struct timeval _framesDroppedCurrentSince;
}

@dynamic duration;

DESIGNATED_INIT

+ (instancetype)videoEncoderWithInputDelegate:(id <IMUTLibMediaEncoderVideoDelegate>)inputDelegate andName:(NSString *)name {
    return [[self alloc] initWithInputDelegate:inputDelegate andName:name];
}

+ (void)initialize {
    mediaSourceId = 0;
}

- (void)startTimer {
    @synchronized (self) {
        if (_timer) {
            return;
        }

        _lastFrameNumber = 0;
        _didWriteFirstFrame = NO;

        _framesDroppedCurrent = 0;
        gettimeofday(&_framesDroppedCurrentSince, NULL);

        self.stopped = NO;

        [self.delegate encoderWillBeginProducingStream];

        _timer = [IMUTLibTimer scheduledTimerWithTimeInterval:_frameSecondFraction
                                                       target:self
                                                     selector:@selector(timerFired:)
                                                     userInfo:nil
                                                      repeats:YES
                                                dispatchQueue:_timerDispatchQueue];
    }
}

- (void)stopTimer {
    @synchronized (self) {
        if (_timer) {
            [self.delegate encoderStoppedProducingStream];

            self.stopped = YES;
            self.dateOfFirstFrame = nil;

            [_timer invalidate];
            _timer = nil;
        }
    }
}

// This method is called every second fraction to produce a new video frame
- (void)timerFired:(IMUTLibTimer *)timer {
    int64_t frameNumber; // Should equal "long long" on armv7/arm64
    struct timeval currentTime;
    double timeDelta;
    CMTime frameTime;
    CVPixelBufferRef pixelBuffer = NULL;

    @synchronized (self) {
        if (self.stopped) {
            return;
        }

        if (_lastFrameNumber > 0) {
            gettimeofday(&currentTime, NULL);
            timeDelta = (currentTime.tv_sec - _baseTime.tv_sec) + (currentTime.tv_usec / 1000000.0 - _baseTime.tv_usec / 1000000.0);
            frameNumber = (int64_t) round(timeDelta / _frameSecondFraction);
        } else {
            gettimeofday(&_baseTime, NULL);
            frameNumber = 1;
        }

        if (frameNumber > _lastFrameNumber && [self.writerInput isReadyForMoreMediaData]) {
            CVReturn status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, _avAssetWriterInputPixelBufferAdaptor.pixelBufferPool, &pixelBuffer);
            if (status == kCVReturnSuccess && pixelBuffer != NULL) {
                CVPixelBufferLockBaseAddress(pixelBuffer, 0);
                frameTime = CMTimeMake(frameNumber, _targetFramerate);
                if ([self.inputDelegate encoder:self populatePixelBuffer:pixelBuffer forTime:frameTime]) {
                    [_avAssetWriterInputPixelBufferAdaptor appendPixelBuffer:pixelBuffer
                                                        withPresentationTime:frameTime];

                    // Save the time when the first frame was successfully recorded
                    if (!_didWriteFirstFrame) {
                        _didWriteFirstFrame = YES;

                        // This could become the time source
                        self.dateOfFirstFrame = [NSDate date];
                    }

                    // Calculate and report dropped frames every 2 seconds
                    if ([(NSObject *) self.inputDelegate respondsToSelector:@selector(encoder:droppedFrames:)]) {
                        _framesDroppedCurrent += frameNumber - _lastFrameNumber - 1;
                        double framesDroppedTimeDelta = (currentTime.tv_sec - _framesDroppedCurrentSince.tv_sec) + (currentTime.tv_usec / 1000000.0 - _framesDroppedCurrentSince.tv_usec / 1000000.0);
                        if (_framesDroppedCurrent > 0 && framesDroppedTimeDelta > 2) {
                            [self.inputDelegate encoder:self droppedFrames:_framesDroppedCurrent];
                            gettimeofday(&_framesDroppedCurrentSince, NULL);
                            _framesDroppedCurrent = 0;
                        }
                    }

                    _lastFrameNumber = frameNumber;
                }
                CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
            }

            if (pixelBuffer != NULL) {
                CVPixelBufferRelease(pixelBuffer);
            }
        }
    }
}

- (CMTime)duration {
    return CMTimeMake(_lastFrameNumber, _targetFramerate);
}

#pragma mark IMUTLibMediaEncoder protocol

- (void)resetDuration {
    @synchronized (self) {
        if (self.stopped) {
            _lastFrameNumber = 0;
        }
    }
}

#pragma mark Private

- (instancetype)initWithInputDelegate:(id <IMUTLibMediaEncoderVideoDelegate>)inputDelegate andName:(NSString *)name {
    if (self = [super init]) {
        self.inputDelegate = inputDelegate;
        self.stopped = YES;
        self.mediaSourceType = IMUTLibMediaSourceTypeVideo;

        _sourceName = name;

        _timerDispatchQueue = makeDispatchQueue([NSString stringWithFormat:@"media_source_video.%d.timer",
                                                                           mediaSourceId++], DISPATCH_QUEUE_SERIAL, DISPATCH_QUEUE_PRIORITY_LOW);

        _targetFramerate = 35;
        _frameSecondFraction = 1.0 / _targetFramerate;

        NSMutableDictionary *compressionProps = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                                         [NSNumber numberWithInteger:_targetFramerate], AVVideoMaxKeyFrameIntervalKey,
                                                                         nil
        ];
        NSMutableDictionary *videoSettings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                                      AVVideoCodecH264, AVVideoCodecKey,
                                                                      compressionProps, AVVideoCompressionPropertiesKey,
                                                                      nil
        ];
        if ([(NSObject *) inputDelegate respondsToSelector:@selector(encoder:videoSettings:)]) {
            [inputDelegate encoder:self videoSettings:videoSettings];
        }
        self.writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                              outputSettings:videoSettings];
        self.writerInput.expectsMediaDataInRealTime = YES;

        NSMutableDictionary *bufferAttributes = [NSMutableDictionary dictionary];
        if ([(NSObject *) inputDelegate respondsToSelector:@selector(encoder:bufferAttributes:)]) {
            [inputDelegate encoder:self bufferAttributes:bufferAttributes];
        }
        _avAssetWriterInputPixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_writerInput
                                                                                                                 sourcePixelBufferAttributes:bufferAttributes];
    }

    return self;
}

@end
