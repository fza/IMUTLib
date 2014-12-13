#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

#import "IMUTLibMediaWriter.h"

typedef NS_ENUM(NSUInteger, IMUTLibMediaSourceType) {
    IMUTLibMediaSourceTypeAudio = 1, // not used at the moment
    IMUTLibMediaSourceTypeVideo = 2
};

// A base class that acts as a decorator for `AVAssetWriterInput` with its variant configurations
@interface IMUTLibMediaSource : NSObject {
@protected
    BOOL _capturing;
    Float64 _currentFrameRate;
    CMTimebaseRef _currentTimebase;

    NSTimeInterval _currentRecordingDuration;
    CMTime _currentSampleTime;
    NSTimeInterval _lastRecordingDuration;
    CMTime _lastSampleTime;

    NSMutableArray *_previousSecTimestamps;

    AVAssetWriterInput *_writerInput;
    IMUTLibMediaSourceType _mediaSourceType;
    __weak IMUTLibMediaWriter *_writer;
}

// YES if rendering and encoding is in progress
@property(nonatomic, readonly, getter=isCapturing) BOOL capturing;

// The current calculated framerate
@property(nonatomic, readonly, assign) double currentFrameRate;

// The current timebase
@property(nonatomic, readonly, assign) CMTimebaseRef currentTimebase;

// When the current recording started
@property(nonatomic, readonly, retain) NSDate *currentRecordingStartDate;

// The duration of the current recording in seconds
@property(nonatomic, readonly, assign) NSTimeInterval currentRecordingDuration;

// The current session's duration in sample time
@property(nonatomic, readonly, assign) CMTime currentSampleTime;

// Start date of the previous rendering session
@property(nonatomic, readonly, retain) NSDate *lastRecordingStartDate;

// Duration of the previous rendering session in seconds
@property(nonatomic, readonly, assign) NSTimeInterval lastRecordingDuration;

// The previous session's duration in sample time
@property(nonatomic, readonly, assign) CMTime lastSampleTime;

// The AVAssetWriterInput instance that all sample data is passed
// for encoding. This is exposed because the `IMUTLibMediaWriter` instance
// this object will be connected with needs it.
@property(nonatomic, readonly, retain) AVAssetWriterInput *writerInput;

// The type of this media source, this is bitmask
@property(nonatomic, readonly, assign) IMUTLibMediaSourceType mediaSourceType;

// The media writer that muxes and writes out all encoded data
@property(nonatomic, readwrite, weak) IMUTLibMediaWriter *writer;

// Depending on the implementation of the actual media source this will start
// producing the media stream by rendering or capturing an input source,
// encoding this data and passing it to the writer. It will also control
// the media writer as it tells the writer to start a new file.
- (BOOL)startCapturing;

// This will wait until the current sample has been produced, then stop the
// capturing timer. It waits until all samples have been encoded/consumed, then
// stops the encoding timer. It then tells the writer to finalize. This
// method shall not block.
- (void)stopCapturing;

@end
