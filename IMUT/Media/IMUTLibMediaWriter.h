#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

#import "IMUTLibMediaSourceDelegate.h"
#import "IMUTLibMediaWriterDelegate.h"

// This is effectively a decorator for `AVAssetWriter`
@interface IMUTLibMediaWriter : NSObject <IMUTLibMediaSourceDelegate>

// The basename of the files to create
@property(nonatomic, readonly, retain) NSString *basename;

// The extension of the files that this writer will create
@property(nonatomic, readonly) NSString *fileExtension;

// The filetype of the files created by this writer
@property(nonatomic, readonly) NSString *fileType;

// Path to the current media file being written to
@property(nonatomic, readonly, retain) NSString *filePath;

// Approximation of the size of the media file currently being written
// or the actual size after the media had been finaliized. Returns
// zero during media finalization.
@property(nonatomic, readonly) unsigned long long fileSize;

// True if the stream writer is currently recording. This is NO if IMUT is paused.
@property(nonatomic, readonly, getter=isWriting) BOOL writing;

// Combined media source types
@property(nonatomic, readonly, assign) NSUInteger mediaSourceTypes;

// Status of the writer
@property(nonatomic, readonly) AVAssetWriterStatus status;

// The recording delegate, typically the module that owns
// this writer.
@property(nonatomic, readwrite, weak) NSObject <IMUTLibMediaWriterDelegate> *delegate;

+ (instancetype)writerWithBasename:(NSString *)basename;

- (void)addMediaSource:(IMUTLibMediaSource *)mediaSource;

@end

