#import "IMUTLibScreenModule.h"
#import "IMUTLibScreenRenderer.h"
#import "IMUTLibScreenModuleConstants.h"
#import "IMUTLibScreenModuleSessionTimer.h"
#import "IMUTLibScreenRecorderStartEvent.h"
#import "IMUTLibScreenRecorderStopEvent.h"
#import "IMUTLibConstants.h"

#define FINALIZATION_TIMEOUT_SECS 5.0

@interface IMUTLibScreenModule () <IMUTLibMediaWriterDelegate, IMUTLibScreenRendererDelegate>

- (BOOL)startRecording;

- (void)stopRecording;

@end

@implementation IMUTLibScreenModule {
    void(^_finalizationBlock)(void);
}

- (instancetype)initWithConfig:(NSDictionary *)config {
    if (self = [super initWithConfig:config]) {
        IMUTLibScreenRenderer *screenRenderer = [IMUTLibScreenRenderer rendererWithConfig:_config];
        screenRenderer.delegate = self;

        _videoSource = [IMUTLibScreenVideoSource videoSourceWithRenderer:screenRenderer targetFrameRate:60];

        _mediaWriter = [IMUTLibMediaWriter writerWithBasename:@"screen"];
        _mediaWriter.delegate = self;
        [_mediaWriter addMediaSource:_videoSource];
    }

    return self;
}

- (BOOL)startRecording {
    return [self.videoSource startCapturing];
}

- (void)stopRecording {
    [self.videoSource stopCapturing];
}

#pragma mark IMUTLibModule class

+ (NSString *)moduleName {
    return kIMUTLibScreenModule;
}

+ (Class <IMUTLibSessionTimer>)sessionTimerClass {
    return [IMUTLibScreenModuleSessionTimer class];
}

+ (IMUTLibModuleType)moduleType {
    return IMUTLibModuleTypeStream | IMUTLibModuleTypeEvented;
}

+ (NSDictionary *)defaultConfig {
    return @{
        kIMUTLibScreenModuleConfigHidePasswordInput : numYES,
        kIMUTLibScreenModuleConfigUseLowResolution : numNO
    };
}

- (IMUTLibPersistableEntityType)defaultEntityType {
    return IMUTLibPersistableEntityTypeOther;
}

- (void)startWithSession:(IMUTLibSession *)session {
    [self startRecording];
}

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
        kIMUTLibScreenModuleRecorderStartEvent,
        kIMUTLibScreenModuleRecorderStopEvent
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
    id sourceEvent = [IMUTLibScreenRecorderStartEvent new];
    [[IMUTLibSourceEventCollection sharedInstance] addSourceEvent:sourceEvent now:YES];
}

- (void)mediaWriter:(IMUTLibMediaWriter *)mediaWriter willFinalizeFileAtPath:(NSString *)path {
    // Inform the recording delegate (= the time source)
    if ([self.delegate respondsToSelector:@selector(recorder:willFinalizeCurrentMediaFileAtPath:)]) {
        [self.delegate recorder:self willFinalizeCurrentMediaFileAtPath:path];
    }
}

- (void)mediaWriter:(IMUTLibMediaWriter *)mediaWriter didFinalizeFileAtPath:(NSString *)path {
    if (_finalizationBlock) {
        id sourceEvent = [[IMUTLibScreenRecorderStopEvent alloc] initWithSampleTime:self.videoSource.lastSampleTime
                                                                           filename:[path lastPathComponent]];
        [[IMUTLibSourceEventCollection sharedInstance] addSourceEvent:sourceEvent now:YES];

        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            _finalizationBlock();
            _finalizationBlock = nil;
        });
    }
}

#pragma mark IMUTLibScreenRendererDelegate protocol

- (void)renderer:(IMUTLibScreenRenderer *)renderer createdNewFrameAtTime:(NSTimeInterval)time {
    // Inform the recording delegate (= the time source)
    if ([self.delegate respondsToSelector:@selector(recorder:createdNewFrameAtTime:)]) {
        [self.delegate recorder:self createdNewFrameAtTime:time];
    }
}

@end

CONSTRUCTOR {
    [IMUTLibMain registerModuleWithClass:[IMUTLibScreenModule class]];
}
