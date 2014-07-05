#import "IMUTLibMediaFileFinalizer.h"
#import "IMUTLibFileManager.h"
#import "IMUTLibConstants.h"
#import "Macros.h"

@interface IMUTLibMediaFileFinalizer ()

- (instancetype)initWithAssetWriter:(AVAssetWriter *)avAssetWriter;

@end

@implementation IMUTLibMediaFileFinalizer {
    __strong id _strongSelf;
    AVAssetWriter *_avAssetWriter;
}

DESIGNATED_INIT

+ (instancetype)finalizerWithAssetWriter:(AVAssetWriter *)avAssetWriter {
    return [[self alloc] initWithAssetWriter:avAssetWriter];
}

- (void)finalizeMediaFileWithCompletionBlock:(void (^)(NSString *path))completionBlock {
    [_avAssetWriter finishWritingWithCompletionHandler:^{
        NSString *path = [_avAssetWriter.outputURL path];
        if ([[path pathExtension] isEqualToString:kTempFileExtension]) {
            path = [IMUTLibFileManager renameTemporaryFileAtPath:path];
        }

        completionBlock(path);

        _strongSelf = nil;
    }];
}

#pragma mark Private

- (instancetype)initWithAssetWriter:(AVAssetWriter *)avAssetWriter {
    if (self = [super init]) {
        _strongSelf = self;
        _avAssetWriter = avAssetWriter;
    }

    return self;
}

@end
