#import <AVFoundation/AVFoundation.h>

@protocol IMUTLibMediaSampleProducer

- (void)configureAVAssetWriterInput:(AVAssetWriterInput *)writerInput;

@end
