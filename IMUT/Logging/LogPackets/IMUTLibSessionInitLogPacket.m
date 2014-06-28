#import "IMUTLibMain+Internal.h"
#import "IMUTLibSessionInitLogPacket.h"
#import "IMUTLibUtil.h"

@implementation IMUTLibSessionInitLogPacket

- (IMUTLibLogPacketType)logPacketType {
    return IMUTLibLogPacketTypeSessionInit;
}

- (NSDictionary *)dictionaryWithSessionId:(NSString *)sessionId packetSequenceNumber:(unsigned long)sequenceNumber {
    NSMutableDictionary *dictionary = [self baseDictionaryWithSessionId:sessionId
                                                         sequenceNumber:sequenceNumber];

    dictionary[@"modules"] = [[[IMUTLibMain imut].config enabledModuleNames] allObjects];
    dictionary[@"meta"] = [IMUTLibUtil metadata];

    [dictionary addEntriesFromDictionary:_additionalParameters];

    return dictionary;
}

@end
