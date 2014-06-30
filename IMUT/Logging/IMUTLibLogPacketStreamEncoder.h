#import <Foundation/Foundation.h>

@protocol IMUTLibLogPacketStreamEncoder;

@protocol IMUTLibLogPacketStreamEncoderDelegate

- (void)encoder:(id <IMUTLibLogPacketStreamEncoder>)encoder encodedData:(NSData *)data;

@optional
- (void)encoder:(id <IMUTLibLogPacketStreamEncoder>)encoder encodingError:(NSError *)error;

@end

@protocol IMUTLibLogPacketStreamEncoder

@property(atomic, readwrite, weak) id <IMUTLibLogPacketStreamEncoderDelegate> delegate;

- (void)encodeObject:(id)object;

- (void)beginEncoding;

- (void)endEncoding;

@end
