#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

@interface IMUTLibMediaFileFinalizer : NSObject

+ (instancetype)finalizerWithAssetWriter:(AVAssetWriter *)avAssetWriter;

- (void)finalizeMediaFileWithCompletionBlock:(void (^)(NSString *absolutePathOfMediaFile))handler;

@end
