#import "IMUTLibFileManager.h"
#import "IMUTLibMediaFileFinalizer.h"
#import "IMUTLibMediaStreamWriter.h"
#import "IMUTLibFunctions.h"
#import "IMUTLibMain+Internal.h"

static dispatch_queue_t finalizationDispatchQueue;

@interface IMUTLibMediaStreamWriter ()

@property(nonatomic, readwrite, retain) NSString *basename;
@property(atomic, readwrite) BOOL writing;

- (id)initWithBasename:(NSString *)basename;

- (void)startWriting;

@end

@implementation IMUTLibMediaStreamWriter {
    AVAssetWriter *_currentAVAssetWriter;
    NSString *_currentFilePath;
    id <IMUTLibMediaEncoder> _audioEncoder;
    id <IMUTLibMediaEncoder> _videoEncoder;
}

+ (void)initialize {
    finalizationDispatchQueue = makeDispatchQueue(
        @"media_stream_writer_finalizer",
        DISPATCH_QUEUE_CONCURRENT,
        DISPATCH_QUEUE_PRIORITY_DEFAULT
    );
}

+ (id)writerWithBasename:(NSString *)basename {
    return [[self alloc] initWithBasename:basename];
}

- (BOOL)hasVideoTrack {
    return _videoEncoder != nil;
}

- (BOOL)hasAudioTrack {
    return _audioEncoder != nil;
}


- (NSNumber *)approxSizeInBytes {
    @synchronized (self) {
        if (self.writing && _currentFilePath) {
            NSError *error;
            NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:_currentFilePath
                                                                                            error:&error];
            if (!error && fileAttributes) {
                return fileAttributes[NSFileSize];
            }
        }
    }

    return nil;
}

- (AVAssetWriterStatus)status {
    @synchronized (self) {
        if (self.writing && _currentAVAssetWriter) {
            return _currentAVAssetWriter.status;
        }

        return AVAssetWriterStatusUnknown;
    }
}

- (void)addMediaEncoder:(id <IMUTLibMediaEncoder>)encoder {
    switch (encoder.mediaSourceType) {
        case IMUTLibMediaSourceTypeAudio:
            NSAssert(!self.hasAudioTrack, @"cannot replace audio media source");

            _audioEncoder = encoder;

            break;

        case IMUTLibMediaSourceTypeVideo:
            NSAssert(!self.hasVideoTrack, @"cannot replace video media source");

            _videoEncoder = encoder;
    }

    encoder.delegate = self;
}

- (void)finalizeAsync:(BOOL)async {
    @synchronized (self) {
        if (self.writing) {
            self.writing = NO;

            // Use a special finalizer object for this job to be able to quickly resume writing another stream
            IMUTLibMediaFileFinalizer *finalizer = [IMUTLibMediaFileFinalizer finalizerWithAssetWriter:_currentAVAssetWriter];

            if (async) {
                dispatch_async(finalizationDispatchQueue, ^{
                    [finalizer finalizeMediaFileWithCompletionHandler:^{}];
                });
            } else {
                [finalizer finalizeMediaFileWithCompletionHandler:^{}];
            }

            // Free some memory
            _currentAVAssetWriter = nil;
            _currentFilePath = nil;
        }
    }
}

- (NSString *)fileExtension {
    if (self.fileType == AVFileTypeMPEGLayer3) {
        return @"mp3";
    }

    // Catch all is always a multi-track media file using a m4v container
    return @"m4v";
}

- (NSString *)fileType {
    if (self.hasVideoTrack) {
        return AVFileTypeAppleM4V;
    }

    if (self.hasAudioTrack) {
        return AVFileTypeMPEGLayer3;
    }

    // Not yet known or have no track at all
    return nil;
}

#pragma mark IMUTLibMediaStreamSourceWriterDelegate

- (void)encoderWillBeginProducingStream {
    @synchronized (self) {
        if (!self.writing) {
            self.writing = YES;

            [self startWriting];
        }
    }
}

- (void)encoderStoppedProducingStream {
    // Only finalize synchronously if the app is about to terminate
    [self finalizeAsync:![[IMUTLibMain imut] isTerminated]];
}

#pragma mark Private

- (id)initWithBasename:(NSString *)basename {
    if (self = [super init]) {
        self.basename = basename;
        self.writing = NO;

        _currentAVAssetWriter = nil;
    }

    return self;
}

- (void)startWriting {
    NSAssert(_audioEncoder != nil || _videoEncoder != nil, @"neither an audio source nor a video source is available.");

    _currentFilePath = [IMUTLibFileManager absoluteFilePathWithBasename:self.basename
                                                              extension:self.fileExtension
                                                       ensureUniqueness:YES isTemporary:YES];

    NSError *error;
    _currentAVAssetWriter = [AVAssetWriter assetWriterWithURL:[NSURL fileURLWithPath:_currentFilePath]
                                                     fileType:self.fileType
                                                        error:&error];

    NSAssert(!error, @"Unable to create an AVAssetWriter");

    AVAssetWriterInput *input;
    if (_audioEncoder) {
        input = _audioEncoder.writerInput;
        if ([_currentAVAssetWriter canAddInput:input]) {
            [_currentAVAssetWriter addInput:input];
        }
    }
    if (_videoEncoder) {
        input = _videoEncoder.writerInput;
        if ([_currentAVAssetWriter canAddInput:input]) {
            [_currentAVAssetWriter addInput:input];
        }
    }

    [_currentAVAssetWriter startWriting];
    [_currentAVAssetWriter startSessionAtSourceTime:kCMTimeZero];
}

@end
