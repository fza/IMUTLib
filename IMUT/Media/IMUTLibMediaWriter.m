#import <CoreMedia/CMSync.h>

#import "IMUTLibMediaWriter.h"
#import "IMUTLibMediaSource.h"
#import "IMUTLibFileManager.h"
#import "IMUTLibMediaFileFinalizer.h"
#import "IMUTLibFunctions.h"

static NSMutableDictionary *writers;

@interface IMUTLibMediaWriter ()

@property(nonatomic, readwrite, retain) NSString *basename;
@property(nonatomic, readwrite, retain) NSString *filePath;
@property(nonatomic, readwrite, getter=isWriting) BOOL writing;
@property(nonatomic, readwrite, assign) NSUInteger mediaSourceTypes;

- (instancetype)initWithBasename:(NSString *)basename;

- (void)_startWriting;

- (void)_stopWriting;

- (dispatch_queue_t)_finalizationDispatchQueue;

@end

@implementation IMUTLibMediaWriter {
    AVAssetWriter *_assetWriter;
    NSMutableSet *_mediaSources;
    unsigned int _activeSourcesCount;

    NSString *_currentFileExtension;
    NSString *_currentFileType;
    NSString *_lastFilePath;
}

@dynamic fileExtension;
@dynamic fileType;
@dynamic fileSize;
@dynamic status;

+ (void)initialize {
    writers = [NSMutableDictionary dictionary];
}

+ (instancetype)writerWithBasename:(NSString *)basename {
    IMUTLibMediaWriter *writer = [writers objectForKey:basename];
    if (writer) {
        return writer;
    }

    writer = [[self alloc] initWithBasename:basename];
    [writers setObject:writer forKey:basename];

    return writer;
}

- (NSString *)fileExtension {
    @synchronized (self) {
        if (_currentFileExtension) {
            return _currentFileExtension;
        }

        if (self.fileType == AVFileTypeMPEGLayer3) {
            return @"mp3";
        }

        // Catch all is always a multi-track media file using a m4v container
        return @"m4v";
    }
}

- (NSString *)fileType {
    @synchronized (self) {
        if (_currentFileType) {
            return _currentFileType;
        }

        if (self.mediaSourceTypes & IMUTLibMediaSourceTypeVideo) {
            return AVFileTypeAppleM4V;
        }

        if (self.mediaSourceTypes & IMUTLibMediaSourceTypeAudio) {
            return AVFileTypeMPEGLayer3;
        }

        // Not yet known or have no track at all
        return nil;
    }
}

- (unsigned long long)fileSize {
    @synchronized (self) {
        NSString *checkFilePath;
        if (self.writing) {
            checkFilePath = self.filePath;
        } else if (_lastFilePath) {
            checkFilePath = _lastFilePath;
        }

        if (checkFilePath) {
            NSError *error;
            NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:checkFilePath
                                                                                            error:&error];
            if (!error && fileAttributes) {
                return [(NSNumber *) fileAttributes[NSFileSize] unsignedLongLongValue];
            }
        }

        return 0;
    }
}

- (void)addMediaSource:(IMUTLibMediaSource *)mediaSource {
    @synchronized (self) {
        NSAssert(![_mediaSources containsObject:mediaSource], @"The media source has already been added to a writer.");
        NSAssert(_activeSourcesCount == 0, @"Cannot change media sources as the writing is still in progress.");

        if (self.mediaSourceTypes & mediaSource.mediaSourceType) {
            IMUTLibMediaSource *previousMediaSource;
            for (previousMediaSource in _mediaSources) {
                if (previousMediaSource.mediaSourceType & mediaSource.mediaSourceType) {
                    break;
                }
            }

            if (previousMediaSource.writer == self) {
                previousMediaSource.writer = nil;
            }

            [_mediaSources removeObject:previousMediaSource];
        }

        self.mediaSourceTypes |= mediaSource.mediaSourceType;

        mediaSource.writer = self;

        [_mediaSources addObject:mediaSource];
    }
}

- (AVAssetWriterStatus)status {
    @synchronized (self) {
        if (_writing) {
            return _assetWriter.status;
        }
    }

    return AVAssetWriterStatusUnknown;
}

#pragma mark IMUTLibMediaSourceDelegate protocol

- (void)mediaSourceWillBeginProducingSamples:(IMUTLibMediaSource *)mediaSource {
    @synchronized (self) {
        if (_activeSourcesCount == 0) {
            [self _startWriting];
        }

        _activeSourcesCount++;
    }
}

// Note: It is the responsibility of the module, which owns the media source objects, to
// tell them to stop producing data. Only if all media sources have stopped, we can
// finalize the media file because there is no more data to come.
- (void)mediaSourceDidStopProducingSamples:(IMUTLibMediaSource *)mediaSource lastSampleTime:(CMTime)lastSampleTime {
    @synchronized (self) {
        _activeSourcesCount--;

        if (_activeSourcesCount == 0) {
            [self _stopWriting];
        }
    }
}

#pragma mark Private

- (instancetype)initWithBasename:(NSString *)basename {
    if (self = [super init]) {
        self.basename = basename;
        self.writing = NO;
        self.mediaSourceTypes = 0;

        _assetWriter = nil;
        _mediaSources = [NSMutableSet set];
        _activeSourcesCount = 0;
    }

    return self;
}

- (void)_startWriting {
    @synchronized (self) {
        self.writing = YES;

        NSAssert(self.mediaSourceTypes != 0, @"No source has been added to this writer.");

        self.filePath = [IMUTLibFileManager absoluteFilePathWithBasename:_basename
                                                               extension:self.fileExtension
                                                        ensureUniqueness:YES
                                                             isTemporary:YES];

        NSError *error;
        _assetWriter = [AVAssetWriter assetWriterWithURL:[NSURL fileURLWithPath:self.filePath]
                                                fileType:self.fileType
                                                   error:&error];

        NSAssert(!error, @"Unable to create an AVAssetWriter.");

        _currentFileType = self.fileType;
        _currentFileExtension = self.fileExtension;
        _lastFilePath = nil;

        for (IMUTLibMediaSource *mediaSource in _mediaSources) {
            NSAssert([_assetWriter canAddInput:mediaSource.writerInput], @"Unable to connect media source with writer.");
            [_assetWriter addInput:mediaSource.writerInput];
        }

        [_assetWriter startWriting];
        [_assetWriter startSessionAtSourceTime:kCMTimeZero];

        // Inform the delegate
        if ([self.delegate respondsToSelector:@selector(mediaWriter:didStartWritingFileAtPath:)]) {
            [self.delegate mediaWriter:self didStartWritingFileAtPath:self.filePath];
        }
    }
}

- (void)_stopWriting {
    @synchronized (self) {
        self.writing = NO;

        // Inform the delegate
        if ([self.delegate respondsToSelector:@selector(mediaWriter:willFinalizeFileAtPath:)]) {
            [self.delegate mediaWriter:self willFinalizeFileAtPath:self.filePath];
        }

        IMUTLibMediaFileFinalizer *finalizer = [IMUTLibMediaFileFinalizer finalizerWithAssetWriter:_assetWriter];

        __weak id weakSelf = self;
        void (^completionBlock)(NSString *) = ^(NSString *path) {
            _lastFilePath = path;

            // Inform the delegate
            if ([self.delegate respondsToSelector:@selector(mediaWriter:didFinalizeFileAtPath:)]) {
                [self.delegate mediaWriter:weakSelf didFinalizeFileAtPath:path];
            }
        };

//        if ([[IMUTLibMain imut] isTerminated]) {
//            dispatch_sync(_finalizationDispatchQueue, finalizationBlock);
//        } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [finalizer finalizeMediaFileWithCompletionBlock:completionBlock];
        });
//        }

        _assetWriter = nil;
        self.filePath = nil;
        _currentFileType = nil;
        _currentFileExtension = nil;
    }
}

- (dispatch_queue_t)_finalizationDispatchQueue {
    static dispatch_queue_t finalizationDispatchQueue;

    @synchronized (self) {
        if (!finalizationDispatchQueue) {
            makeDispatchQueue(
                @"media_stream_writer_finalizer",
                DISPATCH_QUEUE_CONCURRENT,
                DISPATCH_QUEUE_PRIORITY_DEFAULT
            );
        }
    }

    return finalizationDispatchQueue;
}

@end

