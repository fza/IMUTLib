#import "IMUTLibAbstractLogPacket.h"
#import "IMUTLibConstants.h"
#import "Macros.h"

static NSString *kParamType = @"type";
static NSString *kParamSessionId = @"sid";
static NSString *kParamSequenceNumber = @"seq";

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
    NSMutableDictionary *dictionary = [self baseDictionaryWithSessionId:sessionId sequenceNumber:sequenceNumber];
    [dictionary addEntriesFromDictionary:[self parameters]];
    [dictionary addEntriesFromDictionary:_additionalParameters];

    return dictionary;
}

- (NSMutableDictionary *)baseDictionaryWithSessionId:(NSString *)sessionId sequenceNumber:(unsigned long)sequenceNumber {
    return $MD(@{
        kParamType : [self stringFromLogPacketType:[self logPacketType]],
        kParamSessionId : sessionId,
        kParamSequenceNumber : @(sequenceNumber)
    });
}

- (NSDictionary *)parameters {
    MethodNotImplementedException(@"parameters");
}

- (void)setAdditionalParameters:(NSDictionary *)parameters {
    [_additionalParameters addEntriesFromDictionary:parameters];
}

- (NSString *)stringFromLogPacketType:(IMUTLibLogPacketType)logPacketType {
    switch (logPacketType) {
        case IMUTLibLogPacketTypeSessionInit:
            return kIMUTLibLogPacketTypeSessionInit;

        case IMUTLibLogPacketTypeSync:
            return kIMUTLibLogPacketTypeSync;

        case IMUTLibLogPacketTypeEvents:
            return kIMUTLibLogPacketTypeEvents;

        case IMUTLibLogPacketTypeFinalize:
            return kIMUTLibLogPacketTypeFinalize;

        default:
            // Never return nil
            return kUnknown;
    }
}

@end
