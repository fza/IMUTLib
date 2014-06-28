#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

@interface IMUTLibMediaFileFinalizer : NSObject

+ (instancetype)finalizerWithAssetWriter:(AVAssetWriter *)avAssetWriter;

- (instancetype)initWithAssetWriter:(AVAssetWriter *)avAssetWriter;

- (void)finalizeMediaFileWithCompletionHandler:(void (^)(void))handler;

@end
