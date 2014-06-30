#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#include "IMUTLibVideoEncoderFunctions.h"

@protocol IMUTLibMediaEncoder;

typedef NS_ENUM(NSUInteger, IMUTLibMediaSourceType) {
    IMUTLibMediaSourceTypeAudio = 1,
    IMUTLibMediaSourceTypeVideo = 2
};

@protocol IMUTLibMediaEncoderDelegate

- (void)encoderWillBeginProducingStream;

- (void)encoderStoppedProducingStream;

@end

@protocol IMUTLibMediaEncoder

// The type if this media source
@property(nonatomic, readonly) IMUTLibMediaSourceType mediaSourceType;

// The actual writer input object
@property(nonatomic, readonly) AVAssetWriterInput *writerInput;

// The writer to pass all data
@property(nonatomic, readwrite, weak) id <IMUTLibMediaEncoderDelegate> delegate;

// The last used timing info
- (IMFrameTimingRef)lastFrameTiming;

// Tell the encoder to start encoding
- (BOOL)start;

// Tell the encoder to finalize
- (void)stop;

@end
