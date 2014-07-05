#import <Foundation/Foundation.h>

#import "IMUTLibLogPacketStreamEncoder.h"

@interface IMUTLibJSONStreamEncoder : NSObject <IMUTLibLogPacketStreamEncoder>

@property(nonatomic, readonly, retain) NSString *fileExtension;

@property(atomic, readwrite, weak) NSObject <IMUTLibLogPacketStreamEncoderDelegate> *delegate;

@end
