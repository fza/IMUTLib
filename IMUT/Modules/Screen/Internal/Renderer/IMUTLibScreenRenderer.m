#import <UIKit/UIKit.h>

#import "IMUTLibScreenRenderer.h"
#import "IMUTLibScreenModuleConstants.h"
#import "IMUTLibMain+Internal.h"
#import "Macros.h"
#import "IMUTLibScreenRenderer+UIViewObservation.h"

@interface IMUTLibScreenRenderer (Rendering)

- (void)mergeView:(UIView *)view withGraphicsContext:(CGContextRef)graphicsContext doTransform:(BOOL)doTransform;

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
- (IMUTLibVideoFrameRenderStatus)renderVideoFrame:(VideoFrameBufferRef)videoFrame withVideoSource:(IMUTLibPollingVideoSource *)videoSource {
    IMUTLibVideoFrameRenderStatus status = IMUTLibVideoFrameStatusFailure;

    IMUTLibMain *imut = [IMUTLibMain imut];
    if ([imut isTerminated] || [imut isPaused]) {
        IMUTLogDebugModule(kIMUTLibScreenModule, @"Prevent black frame.");
    } else {

        @try {
            // (1) Begin new graphics context
            UIGraphicsBeginImageContextWithOptions(_screenSize, NO, _screenScale);
            CGContextRef graphicsContext = UIGraphicsGetCurrentContext();

            // (2) Render screen in graphics context
            BOOL hasTakenStatusBarSnapshot = NO;
            NSArray *windows = [[UIApplication sharedApplication] windows];
            // Iterate over all windows and merge them
            for (UIWindow *window in windows) {
                // First are special windows, which are actually no windows, but UIView instances
                // Second is the main screen, which is actually also a view
                if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen]) {
                    [self mergeView:window withGraphicsContext:graphicsContext doTransform:NO];
                }

                NSUInteger currentWindowIndex = [windows indexOfObject:window];

                if (windows.count > currentWindowIndex + 1) {
                    UIWindow *nextWindow = [windows objectAtIndex:currentWindowIndex + 1];
                    if ((nextWindow && nextWindow.windowLevel > UIWindowLevelStatusBar) || !hasTakenStatusBarSnapshot) {
                        [self mergeView:[[self class] activeUIStatusBar]
                    withGraphicsContext:graphicsContext
                            doTransform:YES];
                        hasTakenStatusBarSnapshot = YES;
                    }
                } else if (!hasTakenStatusBarSnapshot) {
                    [self mergeView:[[self class] activeUIStatusBar]
                withGraphicsContext:graphicsContext
                        doTransform:NO];
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
        } @catch (NSException *exception) {}
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

- (void)videoSource:(IMUTLibPollingVideoSource *)videoSource getTargetDispatchQueue:(dispatch_queue_t *)dispatch_queue {
    //*dispatch_queue = dispatch_get_main_queue();
}

- (void)videoSource:(IMUTLibPollingVideoSource *)videoSource failedProcessingFrameAtTime:(CMTime)time reason:(IMUTLibVideoSourceFailedReason)reason {
    // TODO What to do if an error occured during encoding?
}

- (void)videoSource:(IMUTLibPollingVideoSource *)videoSource didProcessFrameAtTime:(CMTime)time {
    if (self.delegate && [self.delegate respondsToSelector:@selector(renderer:createdNewFrameAtTime:)]) {
        [self.delegate renderer:self createdNewFrameAtTime:(double) CMTimeGetSeconds(time)];
    }
}

- (void)videoSource:(IMUTLibPollingVideoSource *)videoSource droppedFrames:(unsigned long)droppedFrames since:(NSTimeInterval)interval {
    IMUTLogDebugModule(kIMUTLibScreenModule, @"Dropped %lu frame(s) since %.2f secs", (unsigned long) droppedFrames, interval);
}

#pragma mark Rendering category

- (void)mergeView:(UIView *)view withGraphicsContext:(CGContextRef)graphicsContext doTransform:(BOOL)doTransform {
    CGContextSaveGState(graphicsContext);
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
