#import <Foundation/Foundation.h>

@protocol IMUTLibLogPacketStreamEncoderDelegate;

// Abstract the log packet encoder, so that it may be possible to have
// additional encoders apart from the generic JSON encoder
@protocol IMUTLibLogPacketStreamEncoder

@property(nonatomic, readonly, retain) NSString *fileExtension;

@property(atomic, readwrite, weak) NSObject <IMUTLibLogPacketStreamEncoderDelegate> *delegate;

- (void)encodeObject:(NSObject *)object;

- (void)beginEncoding;

- (void)endEncoding;

@end

// The delegate onto which an encoder should posts its streamed encoded data or errors
@protocol IMUTLibLogPacketStreamEncoderDelegate

- (void)encoder:(NSObject <IMUTLibLogPacketStreamEncoder> *)encoder encodedData:(NSData *)data;

@optional
- (void)encoder:(NSObject <IMUTLibLogPacketStreamEncoder> *)encoder encodingError:(NSError *)error;

@end
