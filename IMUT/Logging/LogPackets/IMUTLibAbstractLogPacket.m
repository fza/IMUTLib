#import "IMUTLibAbstractLogPacket.h"
#import "IMUTLibConstants.h"
#import "Macros.h"
#import "IMUTLibMain+Internal.h"

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

- (NSDictionary *)dictionaryWithSequence:(unsigned long)sequence {
    NSMutableDictionary *dictionary = $MD(@{
        kParamType : [self stringFromLogPacketType:[self logPacketType]],
        kParamSessionId : [IMUTLibMain imut].session.sessionId,
        kParamSequenceNumber : @(sequence)
    });

    [dictionary addEntriesFromDictionary:[self parameters]];
    [dictionary addEntriesFromDictionary:_additionalParameters];

    return dictionary;
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

        case IMUTLibLogPacketTypeFinal:
            return kIMUTLibLogPacketTypeFinal;

        default:
            // Never return nil
            return kUnknown;
    }
}

@end
