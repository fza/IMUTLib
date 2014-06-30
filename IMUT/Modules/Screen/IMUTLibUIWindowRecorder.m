#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>
#import <libkern/OSAtomic.h>
#import "IMUTLibVideoEncoder.h"
#import "IMUTLibUIWindowRecorder.h"
#import "IMUTLibScreenModuleConstants.h"
#import "Macros.h"

//typedef struct RenderViewContext {
//    __unsafe_unretained UIView *view;
//    CGContextRef graphicsContext;
//    BOOL transform;
//} RenderViewContext;
//
//typedef RenderViewContext *RenderViewContextRef;

@interface IMUTLibUIWindowRecorder ()

@property(atomic, readwrite, retain) NSDate *recordingStartDate;

- (instancetype)initWithMediaStreamWriter:(IMUTLibMediaStreamWriter *)mediaStreamWriter config:(NSDictionary *)config;

@end

@interface IMUTLibUIWindowRecorder (Rendering)

- (void)mergeView:(UIView *)view withGraphicsContext:(CGContextRef)graphicsContext doTransform:(BOOL)doTransform;

//- (void)renderViewWithRenderContextValue:(NSValue *)renderViewContextValue;

@end

// Some of this code is influenced by OTScreenshotHelper.
// @see https://github.com/OpenFibers/OTScreenshotHelper
@implementation IMUTLibUIWindowRecorder {
    IMUTLibVideoEncoder *_encoder;
    NSDictionary *_config;

    CGSize _screenSize;
    CGFloat _screenScale;

    OSSpinLock _startLock;
    OSSpinLock _recordingLock;

}

@dynamic recordingDuration;

+ (instancetype)recorderWithMediaStreamWriter:(IMUTLibMediaStreamWriter *)mediaStreamWriter config:(NSDictionary *)config {
    return [[self alloc] initWithMediaStreamWriter:mediaStreamWriter config:config];
}

- (NSTimeInterval)recordingDuration {
    if (_recordingStartDate) {
        // Will return a copy, which must be released
        IMUTFrameTimingRef frameTiming = [_encoder lastFrameTiming];
        NSTimeInterval frameTimeInterval = frameTiming != NULL ? frameTiming->frameTime : 0;
        IMUTFrameTimingRelease(&frameTiming);

        return frameTimeInterval;
    }

    // Not started yet
    return 0;
}

- (BOOL)startRecording {
    if (class_respondsToSelector([UIView class], @selector(drawViewHierarchyInRect:afterScreenUpdates:))) {
        if(!OSSpinLockTry(&_recordingLock)) {
            // Already recording
            return YES;
        }

        OSSpinLockLock(&_startLock);
        BOOL status = [_encoder start];
        if (status) {
            // Try to aquire the lock again
            OSSpinLockLock(&_startLock);
        }

        OSSpinLockUnlock(&_startLock);

        return status;
    }

    return NO;
}

- (void)stopRecording {
    // If we are unable to aquire the lock, we are actually in the middle of recording
    if(!OSSpinLockTry(&_recordingLock)) {
        _lastRecordingDuration = self.recordingDuration;

        [_encoder stop];

        self.recordingStartDate = nil;
        OSSpinLockUnlock(&_recordingLock);
    }
}

#pragma mark IMUTLibMediaSourceVideoDelegate

- (IMUTLibPixelBufferPopulationStatus)forEncoder:(IMUTLibVideoEncoder *)encoder renderFrameInPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    // (1) Begin new graphics context
    UIGraphicsBeginImageContextWithOptions(_screenSize, NO, _screenScale);
    CGContextRef graphicsContext = UIGraphicsGetCurrentContext();

    // (2) Render screen in graphics context
    //BOOL hasTakenStatusBarSnapshot = NO;
    NSArray *windows = [[UIApplication sharedApplication] windows];
    // Iterate over all windows and merge them
    for (UIWindow *window in windows) {
        // First are special windows, which are actually no windows, but UIView instances
        // Second is the main screen, which is actually also a view
        //if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen]) {
        [self mergeView:window withGraphicsContext:graphicsContext doTransform:NO];
        //}

        //NSUInteger currentWindowIndex = [windows indexOfObject:window];
        //NSLog(@"current window index: %d (count: %d)", currentWindowIndex, windows.count);

//            if (windows.count > currentWindowIndex + 1) {
//                UIWindow *nextWindow = [windows objectAtIndex:currentWindowIndex + 1];
//                if ((nextWindow && nextWindow.windowLevel > UIWindowLevelStatusBar) || !hasTakenStatusBarSnapshot) {
//                    [self mergeView:[[self class] activeUIStatusBar] withGraphicsContext:graphicsContext doTransform:YES];
//                    hasTakenStatusBarSnapshot = YES;
//                }
//            } else if (!hasTakenStatusBarSnapshot) {
//                [self mergeView:[[self class] activeUIStatusBar] withGraphicsContext:graphicsContext doTransform:YES];
//                hasTakenStatusBarSnapshot = YES;
//            }
    }

    BOOL success = NO;
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    if (snapshotImage) {
        CGImageRef cgImage = CGImageCreateCopy([snapshotImage CGImage]);
        if (cgImage != NULL) {
            CFDataRef imageData = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
            if (imageData != NULL) {
                CFRange dataRange = CFRangeMake(0, CFDataGetLength(imageData));
                uint8_t *destPixels = CVPixelBufferGetBaseAddress(pixelBuffer);
                if (destPixels != NULL) {
                    CFDataGetBytes(imageData, dataRange, destPixels);
                    success = YES;
                }
            }
            CFRelease(imageData);
        }
        CGImageRelease(cgImage);
    }

    UIGraphicsEndImageContext();

    if (success) {
        return IMUTLibPixelBufferPopulationStatusSuccess;
    }

    return IMUTLibPixelBufferPopulationStatusFailure;
}

- (void)encoder:(IMUTLibVideoEncoder *)encoder failedEncodingFrameWithTiming:(IMUTFrameTimingRef)timing reason:(IMUTLibVideoEncodingFailedReason)reason {
    // TODO What to do if an error occured during encoding?
}

- (void)encoder:(IMUTLibVideoEncoder *)encoder didEncodeFrameWithTiming:(IMUTFrameTimingRef)timing {
    if(!OSSpinLockTry(&_startLock)) {
        _recordingStartDate = [NSDate date];

        // Unlock to inform that we actually started, which we only did after
        // encoding the first frame.
        OSSpinLockUnlock(&_startLock);
    }
}

- (void)encoder:(IMUTLibVideoEncoder *)encoder droppedFrames:(NSUInteger)droppedFrames {
    IMUTLogDebugModule(kIMUTLibScreenModule, @"Dropped %lu frame(s)", (unsigned long) droppedFrames);
}

- (void)forEncoder:(IMUTLibVideoEncoder *)encoder checkVideoSettings:(NSMutableDictionary *)videoSettings {
    CGRect screenRect = [UIScreen mainScreen].bounds;
    CGFloat screenScale = [UIScreen mainScreen].scale;
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
}

- (void)forEncoder:(IMUTLibVideoEncoder *)encoder checkBufferAttributes:(NSMutableDictionary *)bufferAttributes {
    [bufferAttributes addEntriesFromDictionary:@{
        (__bridge NSString *) kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)
    }];
}

#pragma mark Rendering category

- (void)mergeView:(UIView *)view withGraphicsContext:(CGContextRef)graphicsContext doTransform:(BOOL)doTransform {
    CGContextSaveGState(graphicsContext);

//    RenderViewContext renderViewContext = { view, graphicsContext, doTransform };
//    NSValue *renderViewContextValue = [NSValue valueWithBytes:&renderViewContext objCType:@encode(RenderViewContext)];
//    [self performSelectorOnMainThread:@selector(renderViewWithRenderContextValue:) withObject:renderViewContextValue waitUntilDone:YES];
//
//
//    [view.layer renderInContext:graphicsContext];
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
    CGContextRestoreGState(graphicsContext);
}

//- (void)renderViewWithRenderContextValue:(NSValue *)renderViewContextValue {
//
//}

#pragma mark Private

- (instancetype)initWithMediaStreamWriter:(IMUTLibMediaStreamWriter *)mediaStreamWriter config:(NSDictionary *)config {
    if (self = [super init]) {
        _config = config;

        UIScreen *mainScreen = [UIScreen mainScreen];
        _screenSize = mainScreen.bounds.size;
        _screenScale = mainScreen.scale;

        _encoder = [IMUTLibVideoEncoder videoEncoderWithInputDelegate:self];
        [mediaStreamWriter addMediaEncoder:_encoder];

        _startLock = OS_SPINLOCK_INIT;
        _recordingLock = OS_SPINLOCK_INIT;
    }

    return self;
}

@end
