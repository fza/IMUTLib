#import "IMUTLibMediaFileFinalizer.h"
#import "IMUTLibConstants.h"
#import "Macros.h"

@implementation IMUTLibMediaFileFinalizer {
    AVAssetWriter *_avAssetWriter;
}

DESIGNATED_INIT

+ (instancetype)finalizerWithAssetWriter:(AVAssetWriter *)avAssetWriter {
    return [[self alloc] initWithAssetWriter:avAssetWriter];
}

- (instancetype)initWithAssetWriter:(AVAssetWriter *)avAssetWriter {
    if (self = [super init]) {
        _avAssetWriter = avAssetWriter;
    }

    return self;
}

- (void)finalizeMediaFileWithCompletionHandler:(void (^)(void))handler {
    void (^actualHandler)(void) = handler;
    if ([[_avAssetWriter.outputURL pathExtension] isEqualToString:IMUTLibTempFileExtension]) {
        // Must rename file after finalization
        actualHandler = ^{
            NSError *error;
            [[NSFileManager defaultManager] moveItemAtURL:_avAssetWriter.outputURL
                                                    toURL:[_avAssetWriter.outputURL URLByDeletingPathExtension]
                                                    error:&error];
            handler();
        };
    }

    [_avAssetWriter finishWritingWithCompletionHandler:actualHandler];
}

@end
