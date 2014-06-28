#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import "IMUTLibMediaEncoder.h"

@interface IMUTLibMediaStreamWriter : NSObject <IMUTLibMediaEncoderDelegate>

// The basename of the files to create
@property(nonatomic, readonly, retain) NSString *basename;

// The extension of the files that this writer will create
@property(nonatomic, readonly, retain) NSString *fileExtension;

// The filetype of the files created by this writer
@property(nonatomic, readonly, retain) NSString *fileType;

// True if the stream writer is currently recording. This is NO if IMUT is paused.
@property(atomic, readonly, assign) BOOL writing;

// True if the stream writer has a video track
@property(nonatomic, readonly, assign) BOOL hasVideoTrack;

// True if the stream writer has a audio track
@property(nonatomic, readonly, assign) BOOL hasAudioTrack;

// Status of the current writer
@property(nonatomic, readonly, assign) AVAssetWriterStatus status;

// Approximation of the size of the media file currently being created
@property(nonatomic, readonly, retain) NSNumber *approxSizeInBytes;

+ (id)writerWithBasename:(NSString *)basename;

- (void)addMediaSourceWithEncoder:(id <IMUTLibMediaEncoder>)encoder;

// Must be invoked when the writer should end streaming data to the current media file an then stop
// writing at all.
- (void)finalizeAsync:(BOOL)async;

@end
