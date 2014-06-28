#import <Foundation/Foundation.h>
#import "IMUTLibSession.h"
#import "IMUTLibLogPacket.h"

@interface IMUTLibAbstractLogPacket : NSObject <IMUTLibLogPacket> {
    NSMutableDictionary *_additionalParameters;
}

- (NSMutableDictionary *)baseDictionaryWithSessionId:(NSString *)sessionId
                                      sequenceNumber:(unsigned long)sequenceNumber;

- (NSDictionary *)parameters;

- (void)setAdditionalParameters:(NSDictionary *)parameters;

- (NSString *)stringFromLogPacketType:(IMUTLibLogPacketType)logPacketType;

@end
