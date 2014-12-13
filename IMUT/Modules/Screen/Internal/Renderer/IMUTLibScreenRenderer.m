#import <UIKit/UIKit.h>

#import "IMUTLibScreenRenderer.h"
#import "IMUTLibScreenRenderer+UIViewObservation.h"
#import "IMUTLibScreenModuleConstants.h"
#import "IMUTLibMain+Internal.h"
#import "Macros.h"

@interface IMUTLibScreenRenderer (Rendering)

- (void)mergeView:(UIView *)view withGraphicsContext:(CGContextRef)graphicsContext;

@end

@interface IMUTLibScreenRenderer ()

- (instancetype)initWithConfig:(NSDictionary *)config;

@end

@implementation IMUTLibScreenRenderer {
    NSDictionary *_config;
    CGSize _screenSize;
    CGFloat _screenScale;
}

+ (instancetype)rendererWithConfig:(NSDictionary *)config {
    return [[self alloc] initWithConfig:config];
}

#pragma mark IMUTLibVideoRenderer protocol

// Called when the encoder wants a new frame
- (IMUTLibVideoFrameRenderStatus)renderVideoFrame:(VideoFrameBufferRef)videoFrame withVideoSource:(IMUTLibScreenVideoSource *)videoSource {
    IMUTLibVideoFrameRenderStatus status = IMUTLibVideoFrameStatusFailure;

    IMUTLibMain *imut = [IMUTLibMain imut];
    if (![imut isTerminated] && ![imut isPaused]) {
        UIGraphicsBeginImageContextWithOptions(_screenSize, NO, _screenScale);
        CGContextRef graphicsContext = UIGraphicsGetCurrentContext();

        BOOL hasTakenStatusBarSnapshot = NO;
        NSArray *windows = [[UIApplication sharedApplication] windows];
        NSUInteger currentWindowIndex = 0;
        for (UIWindow *window in windows) {
            if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen]) {
                [self mergeView:window withGraphicsContext:graphicsContext];
            }

            currentWindowIndex++;

            if (windows.count > currentWindowIndex + 1) {
                UIWindow *nextWindow = windows[currentWindowIndex + 1];
                if ((nextWindow && nextWindow.windowLevel > UIWindowLevelStatusBar) || !hasTakenStatusBarSnapshot) {
                    [self mergeView:[[self class] activeUIStatusBar] withGraphicsContext:graphicsContext];
                    hasTakenStatusBarSnapshot = YES;
                }
            } else if (!hasTakenStatusBarSnapshot) {
                [self mergeView:[[self class] activeUIStatusBar] withGraphicsContext:graphicsContext];
                hasTakenStatusBarSnapshot = YES;
            }
        }

        UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
        if (snapshotImage) {
            CGImageRef cgImage = CGImageCreateCopy([snapshotImage CGImage]);
            if (cgImage != NULL) {
                CFDataRef imageData = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
                if (imageData != NULL) {
                    CFRange dataRange = CFRangeMake(0, CFDataGetLength(imageData));
                    uint8_t *destPixels = CVPixelBufferGetBaseAddress(VideoFrameGetPixelBuffer(videoFrame));
                    if (destPixels != NULL) {
                        CFDataGetBytes(imageData, dataRange, destPixels);
                        status = IMUTLibVideoFrameStatusSuccess;
                    }
                }
                CFRelease(imageData);
            }
            CGImageRelease(cgImage);
        }

        UIGraphicsEndImageContext();
    }

    return status;
}

- (NSDictionary *)bufferAttributesUsingDefaults:(NSMutableDictionary *)bufferAttributes {
    // Passthrough
    return bufferAttributes;
}

- (NSDictionary *)videoSettingsUsingDefaults:(NSMutableDictionary *)videoSettings {
    UIScreen *mainScreen = [UIScreen mainScreen];
    CGRect screenRect = mainScreen.bounds;
    CGFloat screenScale = mainScreen.scale;
    int width = (int) ceil(screenRect.size.width * screenScale);
    int height = (int) ceil(screenRect.size.height * screenScale);
    double bitRateFactor = [(NSNumber *) _config[kIMUTLibScreenModuleConfigUseLowResolution] boolValue] ? 3.2 : 8.0;
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

- (void)videoSource:(IMUTLibScreenVideoSource *)videoSource didProcessFrameAtTime:(CMTime)time {
    if (self.delegate && [self.delegate respondsToSelector:@selector(renderer:createdNewFrameAtTime:)]) {
        [self.delegate renderer:self createdNewFrameAtTime:(double) CMTimeGetSeconds(time)];
    }
}

- (void)videoSource:(IMUTLibScreenVideoSource *)videoSource droppedFrames:(unsigned long)droppedFrames since:(NSTimeInterval)interval {
    IMUTLogDebugModule(kIMUTLibScreenModule, @"Dropped %lu frame(s) in %.2f secs", (unsigned long) droppedFrames, interval);
}

#pragma mark Rendering category

- (void)mergeView:(UIView *)view withGraphicsContext:(CGContextRef)graphicsContext {
    CGContextSaveGState(graphicsContext);
    //[view.layer renderInContext:graphicsContext];
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
    CGContextRestoreGState(graphicsContext);
}

#pragma mark Private

- (instancetype)initWithConfig:(NSDictionary *)config {
    if (self = [super init]) {
        _config = config;

        UIScreen *mainScreen = [UIScreen mainScreen];
        _screenSize = mainScreen.bounds.size;
        _screenScale = mainScreen.scale;
    }

    return self;
}

@end
