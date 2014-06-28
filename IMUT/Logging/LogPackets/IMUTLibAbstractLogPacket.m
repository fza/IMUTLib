#import "IMUTLibAbstractLogPacket.h"
#import "IMUTLibConstants.h"
#import "Macros.h"

@implementation IMUTLibAbstractLogPacket

- (instancetype)init {
    if (self = [super init]) {
        _additionalParameters = [NSMutableDictionary dictionary];
    }

    return self;
}

- (IMUTLibLogPacketType)logPacketType {
    MethodNotImplementedException(@"logPacketType");
}

- (NSDictionary *)dictionaryWithSessionId:(NSString *)sessionId packetSequenceNumber:(unsigned long)sequenceNumber {
    MethodNotImplementedException(@"dictionaryWithSessionId:packetSequenceNumber:");
}

- (NSMutableDictionary *)baseDictionaryWithSessionId:(NSString *)sessionId sequenceNumber:(unsigned long)sequenceNumber {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    dictionary[@"type"] = [self stringFromLogPacketType:[self logPacketType]];
    dictionary[@"sid"] = sessionId;
    dictionary[@"seq"] = [NSNumber numberWithLong:sequenceNumber];

    return dictionary;
}

- (void)setAdditionalParameters:(NSDictionary *)parameters {
    [_additionalParameters addEntriesFromDictionary:parameters];
}

- (NSString *)stringFromLogPacketType:(IMUTLibLogPacketType)logPacketType {
    static NSString *kUnknown = @"unknown";

    switch (logPacketType) {
        case IMUTLibLogPacketTypeSessionInit:
            return kIMUTLibLogPacketTypeSessionInit;

        case IMUTLibLogPacketTypeSync:
            return kIMUTLibLogPacketTypeSync;

        case IMUTLibLogPacketTypeEvents:
            return kIMUTLibLogPacketTypeEvents;

        default:
            // Never return nil
            return kUnknown;
    }
}

@end
