#import "IMUTLibLogPacket.h"
#import "IMUTLibConstants.h"
#import "Macros.h"

static NSString *kParamType = @"type";
static NSString *kParamSessionId = @"sid";
static NSString *kParamSequenceNumber = @"seq";

@implementation IMUTLibLogPacket

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
    // Base packet data (type, session, sequence number)
    NSMutableDictionary *dictionary = $MD(@{
        kParamType : [self stringFromLogPacketType:[self logPacketType]],
        kParamSessionId : [IMUTLibMain imut].session.sessionId,
        kParamSequenceNumber : @(sequence)
    });

    // Merge in data specific to the concrete log packet
    [dictionary addEntriesFromDictionary:[self parameters]];

    // Merge in any additional parameters
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
