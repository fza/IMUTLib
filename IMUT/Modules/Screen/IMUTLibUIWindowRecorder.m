#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>
#import "IMUTLibMediaFrameBasedVideoEncoder.h"
#import "IMUTLibUIWindowRecorder.h"
#import "IMUTLibScreenModuleConstants.h"
#import "IMUTLibUIWindowRecorder+UIViewObservation.h"
#import "Macros.h"

@interface IMUTLibUIWindowRecorder ()

- (instancetype)initWithMediaStreamWriter:(IMUTLibMediaStreamWriter *)mediaStreamWriter config:(NSDictionary *)config;

@end

// Some of this code is influenced by OTScreenshotHelper.
// @see https://github.com/OpenFibers/OTScreenshotHelper
@implementation IMUTLibUIWindowRecorder {
    NSDictionary *_config;
}

@dynamic duration;

@synthesize dateOfFirstFrame = _dateOfFirstFrame;
@synthesize mediaEncoder = _mediaEncoder;

+ (instancetype)recorderWithMediaStreamWriter:(IMUTLibMediaStreamWriter *)mediaStreamWriter config:(NSDictionary *)config {
    return [[self alloc] initWithMediaStreamWriter:mediaStreamWriter config:config];
}

- (NSDate *)dateOfFirstFrame {
    return _mediaEncoder.dateOfFirstFrame;
}

- (IMUTLibMediaFrameBasedVideoEncoder *)mediaEncoder {
    return _mediaEncoder;
}

- (double)duration {
    CMTime duration = _mediaEncoder.duration;

    return ((double) duration.value) / duration.timescale;
}

- (void)resetDuration {
    [_mediaEncoder resetDuration];
}

- (void)startRecording {
    [_mediaEncoder startTimer];
}

- (void)stopRecording {
    [_mediaEncoder stopTimer];
}

- (void)renderScreenInGraphicsContext:(CGContextRef)graphicsContext {
    BOOL hasTakenStatusBarSnapshot = NO;
    NSArray *windows = [[UIApplication sharedApplication] windows];
    for (UIWindow *window in windows) {
        if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen]) {
            [self mergeView:window withGraphicsContext:graphicsContext doTransform:NO];
        }

        NSUInteger currentWindowIndex = [windows indexOfObject:window];
        if (windows.count > currentWindowIndex + 1) {
            UIWindow *nextWindow = [windows objectAtIndex:currentWindowIndex + 1];
            if (nextWindow.windowLevel > UIWindowLevelStatusBar || !hasTakenStatusBarSnapshot) {
                [self mergeView:[[self class] activeUIStatusBar] withGraphicsContext:graphicsContext doTransform:YES];
                hasTakenStatusBarSnapshot = YES;
            }
        } else if (!hasTakenStatusBarSnapshot) {
            [self mergeView:[[self class] activeUIStatusBar] withGraphicsContext:graphicsContext doTransform:YES];
            hasTakenStatusBarSnapshot = YES;
        }
    }
}

- (void)mergeView:(UIView *)view withGraphicsContext:(CGContextRef)graphicsContext doTransform:(BOOL)doTransform {
    CGContextSaveGState(graphicsContext);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
    CGContextRestoreGState(graphicsContext);
}

- (void)renderCurrentGraphicsContextInPixelBuffer:(CVPixelBufferRef)pixelBuffer forTime:(CMTime)frameTime {
    // Get generated snapshot
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    // Generate data representation from snapshot image and write to pixel buffer
    CGImageRef cgImage = CGImageCreateCopy([snapshotImage CGImage]);
    CFDataRef imageData = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));

    uint8_t *destPixels = CVPixelBufferGetBaseAddress(pixelBuffer);
    CFDataGetBytes(imageData, CFRangeMake(0, CFDataGetLength(imageData)), destPixels);

    // Cleanup
    CFRelease(imageData);
    CGImageRelease(cgImage);
}

#pragma mark IMUTLibMediaSourceVideoDelegate

- (BOOL)encoder:(IMUTLibMediaFrameBasedVideoEncoder *)encoder populatePixelBuffer:(CVPixelBufferRef)pixelBuffer forTime:(CMTime)frameTime {
    UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen].bounds.size, NO, [UIScreen mainScreen].scale);
    CGContextRef graphicsContext = UIGraphicsGetCurrentContext();
    [self renderScreenInGraphicsContext:graphicsContext];
    [self renderCurrentGraphicsContextInPixelBuffer:pixelBuffer forTime:frameTime];

    return YES;
}

- (void)encoder:(IMUTLibMediaFrameBasedVideoEncoder *)encoder videoSettings:(NSMutableDictionary *)videoSettings {
    CGRect screenRect = [UIScreen mainScreen].bounds;
    CGFloat screenScale = [UIScreen mainScreen].scale;
    int width = (int) ceil(screenRect.size.width * screenScale);
    int height = (int) ceil(screenRect.size.height * screenScale);
    double bitRateFactor = [(NSNumber *) _config[kIMUTLibScreenModuleConfigUseLowResolution] boolValue] ? 3.2 : 8.0;
    int avgBitrate = (int) ceil(width * height * bitRateFactor);

    [videoSettings addEntriesFromDictionary:@{
        AVVideoWidthKey:@(width),
        AVVideoHeightKey:@(height)
    }];

    [[videoSettings objectForKey:AVVideoCompressionPropertiesKey] addEntriesFromDictionary:@{
        AVVideoAverageBitRateKey:@(avgBitrate),
    }];
}

- (void)encoder:(IMUTLibMediaFrameBasedVideoEncoder *)encoder bufferAttributes:(NSMutableDictionary *)bufferAttributes {
    [bufferAttributes addEntriesFromDictionary:@{
        (__bridge NSString *) kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)
    }];
}

- (void)encoder:(IMUTLibMediaFrameBasedVideoEncoder *)encoder droppedFrames:(NSUInteger)droppedFrames {
    IMUTLogDebugModule(kIMUTLibScreenModule, @"Dropped %lu frame(s)", (unsigned long) droppedFrames);
}

#pragma mark Private

- (instancetype)initWithMediaStreamWriter:(IMUTLibMediaStreamWriter *)mediaStreamWriter config:(NSDictionary *)config {
    if (self = [super init]) {
        // Ensure iOS 7+
        NSAssert(
                class_respondsToSelector([UIView class], @
                selector(drawViewHierarchyInRect:afterScreenUpdates:)),
                @"Platform does not respond to `drawViewHierarchyInRect:afterScreenUpdates:` on `UIView` instances. Cannot record the screen. Abort."
            );

        _config = config;
        _mediaEncoder = [IMUTLibMediaFrameBasedVideoEncoder videoEncoderWithInputDelegate:self
                                                                                  andName:kIMUTLibScreenModule];
        [mediaStreamWriter addMediaSourceWithEncoder:_mediaEncoder];
    }

    return self;
}

@end
