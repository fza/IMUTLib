#import <Foundation/Foundation.h>
#import "IMUTLibLogPacket.h"
#import "IMUTLibLogPacketStreamEncoder.h"

@interface IMUTLibJSONStreamEncoder : NSObject <IMUTLibLogPacketStreamEncoder>

@property(atomic, readwrite, weak) id <IMUTLibLogPacketStreamEncoderDelegate> delegate;

@end
