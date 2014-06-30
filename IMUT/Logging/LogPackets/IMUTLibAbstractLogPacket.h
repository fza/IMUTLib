#import <Foundation/Foundation.h>
#import "IMUTLibSession.h"
#import "IMUTLibLogPacket.h"

@interface IMUTLibAbstractLogPacket : NSObject <IMUTLibLogPacket> {
    NSMutableDictionary *_additionalParameters;
}

- (NSDictionary *)parameters;

- (void)setAdditionalParameters:(NSDictionary *)parameters;

- (NSString *)stringFromLogPacketType:(IMUTLibLogPacketType)logPacketType;

@end
