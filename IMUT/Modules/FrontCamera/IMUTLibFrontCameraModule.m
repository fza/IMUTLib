#import "IMUTLibFrontCameraModule.h"
#import "IMUTLibFrontCameraModuleConstants.h"
#import "IMUTLibFrontCameraRecorderStartEvent.h"
#import "IMUTLibFrontCameraRecorderStopEvent.h"
#import "IMUTLibConstants.h"

#define FINALIZATION_TIMEOUT_SECS 5.0

@interface IMUTLibFrontCameraModule () <IMUTLibMediaWriterDelegate, IMUTLibVideoCapturerDelegate>

- (BOOL)startRecording;

- (void)stopRecording;

@end

@implementation IMUTLibFrontCameraModule {
    void(^_finalizationBlock)(void);
}

- (instancetype)initWithConfig:(NSDictionary *)config {
    if (self = [super initWithConfig:config]) {
        AVCaptureDevice *frontCameraDevice;
        for (AVCaptureDevice *device in [AVCaptureDevice devices]) {
            if (device.position == AVCaptureDevicePositionFront) {
                frontCameraDevice = device;

                break;
            }
        }

        if (frontCameraDevice) {
            NSError *error;
            AVCaptureDeviceInput *captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:frontCameraDevice
                                                                                             error:&error];

            if (!error) {
                _videoSource = [IMUTLibDeviceCapturingSource captureSourceWithInputDevice:captureDeviceInput
                                                                          targetFrameRate:30];
                _videoSource.delegate = self;

                _mediaWriter = [IMUTLibMediaWriter writerWithBasename:@"frontcamera"];
                _mediaWriter.delegate = self;
                [_mediaWriter addMediaSource:self.videoSource];

                return self;
            }
        }
    }

    return nil;
}

- (BOOL)startRecording {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];

    __block BOOL ret = NO;
    if (authStatus != AVAuthorizationStatusAuthorized) {
        dispatch_group_t dispatchGroup = dispatch_group_create();
        dispatch_group_enter(dispatchGroup);

        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted){
            if (granted) {
                ret = [self.videoSource startCapturing];
                dispatch_group_leave(dispatchGroup);
            }
        }];

        dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER);
    } else {
        ret = [self.videoSource startCapturing];
    }

    return ret;
}

- (void)stopRecording {
    [self.videoSource stopCapturing];
}

#pragma mark IMUTLibModule class

+ (NSString *)moduleName {
    return kIMUTLibFrontCameraModule;
}

+ (IMUTLibModuleType)moduleType {
    return IMUTLibModuleTypeStream | IMUTLibModuleTypeEvented;
}

+ (NSDictionary *)defaultConfig {
    return @{
        kIMUTLibFrontCameraModuleConfigUseLowResolution : numNO
    };
}

- (IMUTLibPersistableEntityType)defaultEntityType {
    return IMUTLibPersistableEntityTypeOther;
}

// Only used if this module doesn't act as time source
- (void)startWithSession:(IMUTLibSession *)session {
    [self startRecording];
}

// Only used if this module doesn't act as time source
- (void)stopWithSession:(IMUTLibSession *)session {
    [self stopRecording];
}

- (void)registerEventAggregatorBlocksInRegistry:(IMUTLibEventAggregatorRegistry *)registry {
    IMUTLibEventAggregatorBlock aggregator = ^IMUTLibAggregatorOperation(NSObject <IMUTLibSourceEvent> *sourceEvent, NSObject <IMUTLibSourceEvent> *lastPersistedSourceEvent, IMUTLibPersistableEntity **deltaEntity) {
        *deltaEntity = [IMUTLibPersistableEntity entityWithSourceEvent:sourceEvent];
        (*deltaEntity).entityType = IMUTLibPersistableEntityTypeOther;

        return IMUTLibAggregationOperationEnqueue;
    };

    [registry registerEventAggregatorBlock:aggregator forEventsWithNames:$(
        kIMUTLibFrontCameraModuleRecorderStartEvent,
        kIMUTLibFrontCameraModuleRecorderStopEvent
    )];
}

- (NSSet *)eventsWithFinalState {
    dispatch_group_t dispatchGroup = dispatch_group_create();
    dispatch_group_enter(dispatchGroup);

    _finalizationBlock = ^{
        dispatch_group_leave(dispatchGroup);
    };

    dispatch_group_wait(dispatchGroup, dispatch_time(DISPATCH_TIME_NOW, (int64_t) (FINALIZATION_TIMEOUT_SECS * NSEC_PER_SEC)));

    return nil;
}

#pragma mark IMUTLibMediaWriterDelegate protocol

- (void)mediaWriter:(IMUTLibMediaWriter *)mediaWriter didStartWritingFileAtPath:(NSString *)path {
    // Enqueue a source event to inform that the media writer started
    id sourceEvent = [IMUTLibFrontCameraRecorderStartEvent new];
    [[IMUTLibSourceEventCollection sharedInstance] addSourceEvent:sourceEvent now:YES];
}

- (void)mediaWriter:(IMUTLibMediaWriter *)mediaWriter willFinalizeFileAtPath:(NSString *)path {
    // Noop
}

- (void)mediaWriter:(IMUTLibMediaWriter *)mediaWriter didFinalizeFileAtPath:(NSString *)path {
    if (_finalizationBlock) {
        id sourceEvent = [[IMUTLibFrontCameraRecorderStopEvent alloc] initWithSampleTime:self.videoSource.lastSampleTime
                                                                                filename:[path lastPathComponent]];
        [[IMUTLibSourceEventCollection sharedInstance] addSourceEvent:sourceEvent now:YES];

        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            _finalizationBlock();
            _finalizationBlock = nil;
        });
    }
}

#pragma mark IMUTLibVideoCapturerDelegate protocol

- (void)capturingSource:(IMUTLibDeviceCapturingSource *)capturingSource giveSessionPreset:(NSString **)sessionPreset {
    *sessionPreset = AVCaptureSessionPresetLow;
}

- (NSDictionary *)videoSettingsUsingDefaults:(NSMutableDictionary *)videoSettings {
    int width = 480;
    int height = 640;
    double bitRateFactor = [(NSNumber *) _config[kIMUTLibFrontCameraModuleConfigUseLowResolution] boolValue] ? 3.2 : 8.0;
    int avgBitrate = (int) ceil(width * height * bitRateFactor);

    [videoSettings addEntriesFromDictionary:@{
        AVVideoWidthKey : @(width),
        AVVideoHeightKey : @(height)
    }];

    [videoSettings[AVVideoCompressionPropertiesKey] addEntriesFromDictionary:@{
        AVVideoAverageBitRateKey : @(avgBitrate),
    }];

    return videoSettings;
}

- (NSDictionary *)bufferAttributesUsingDefaults:(NSMutableDictionary *)bufferAttributes {
    // Passthrough
    return bufferAttributes;
}

@end

CONSTRUCTOR {
    [IMUTLibMain registerModuleWithClass:[IMUTLibFrontCameraModule class]];
}
