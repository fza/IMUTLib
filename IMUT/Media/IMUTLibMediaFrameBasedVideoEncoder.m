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
    unsigned long long _lastFrameNumber;
    int _targetFramerate;
    double _frameSecondFraction;
    NSTimeInterval _referenceTime;
    IMUTLibTimer *_timer;
    BOOL _didWriteFirstFrame;
    NSString *_sourceName;
    NSUInteger _framesDropped;
    NSTimeInterval _framesDroppedReferenceTime;
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
    if (_timer) {
        return;
    }

    _lastFrameNumber = 0;
    _didWriteFirstFrame = NO;
    _framesDropped = 0;
    _referenceTime = _framesDroppedReferenceTime = uptime();

    self.stopped = NO;

    [self.delegate encoderWillBeginProducingStream];

    _timer = repeatingTimer(_frameSecondFraction, self, @selector(timerFired), _timerDispatchQueue);
    [_timer schedule];
}

- (void)stopTimer {
    if (_timer) {
        [self.delegate encoderStoppedProducingStream];

        self.stopped = YES;
        self.dateOfFirstFrame = nil;

        [_timer invalidate];
        _timer = nil;
    }
}

// This method is called every second fraction to produce a new video frame
- (void)timerFired {
    if (self.stopped) {
        return;
    }

    double nowTime = uptime();
    unsigned long long frameNumber = _lastFrameNumber > 0 ? (unsigned long long) round((nowTime - _referenceTime) / _frameSecondFraction) : 1;
    CMTime frameTime = CMTimeMake(frameNumber, _targetFramerate);
    CVPixelBufferRef pixelBuffer = NULL;

    if (frameNumber > _lastFrameNumber && [self.writerInput isReadyForMoreMediaData]) {
        CVReturn status = CVPixelBufferPoolCreatePixelBuffer(
            kCFAllocatorDefault,
            _avAssetWriterInputPixelBufferAdaptor.pixelBufferPool,
            &pixelBuffer
        );

        if (status == kCVReturnSuccess && pixelBuffer != NULL) {
            CVPixelBufferLockBaseAddress(pixelBuffer, 0);

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
                    _framesDropped += frameNumber - _lastFrameNumber - 1;
                    if (_framesDropped > 0 && nowTime - _framesDroppedReferenceTime > 2) {
                        [self.inputDelegate encoder:self droppedFrames:_framesDropped];
                        _framesDroppedReferenceTime = nowTime;
                        _framesDropped = 0;
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
        _targetFramerate = 35;
        _frameSecondFraction = 1.0 / _targetFramerate;
        _timerDispatchQueue = makeDispatchQueue(
            [NSString stringWithFormat:@"media_source_video.%d.timer", mediaSourceId++],
            DISPATCH_QUEUE_SERIAL,
            DISPATCH_QUEUE_PRIORITY_LOW
        );

        NSMutableDictionary *bufferAttributes = $MD(@{});
        NSMutableDictionary *videoSettings = $MD(@{
            AVVideoCodecKey : AVVideoCodecH264,
            AVVideoCompressionPropertiesKey : $MD(@{
                AVVideoMaxKeyFrameIntervalKey : @(_targetFramerate)
            })
        });

        if ([(NSObject *) inputDelegate respondsToSelector:@selector(encoder:videoSettings:)]) {
            [inputDelegate encoder:self videoSettings:videoSettings];
        }
        if ([(NSObject *) inputDelegate respondsToSelector:@selector(encoder:bufferAttributes:)]) {
            [inputDelegate encoder:self bufferAttributes:bufferAttributes];
        }

        self.writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                              outputSettings:videoSettings];
        self.writerInput.expectsMediaDataInRealTime = YES;

        _avAssetWriterInputPixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_writerInput
                                                                                                                 sourcePixelBufferAttributes:bufferAttributes];
    }

    return self;
}

@end
