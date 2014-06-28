#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

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
@property(nonatomic, readonly, assign) IMUTLibMediaSourceType mediaSourceType;

// The actual writer input object
@property(nonatomic, readonly, retain) AVAssetWriterInput *writerInput;

// The writer to pass all data
@property(nonatomic, readwrite, assign) id <IMUTLibMediaEncoderDelegate> delegate;

// Wether this media source has stopped producing data
@property(nonatomic, readonly, assign) BOOL stopped;

- (void)resetDuration;

@end
