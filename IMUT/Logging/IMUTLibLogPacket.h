#import <Foundation/Foundation.h>

// These are the currently implementd log packet types
typedef NS_ENUM(NSUInteger, IMUTLibLogPacketType) {
    IMUTLibLogPacketTypeSessionInit = 1,
    IMUTLibLogPacketTypeSync = 2,
    IMUTLibLogPacketTypeEvents = 3,
    IMUTLibLogPacketTypeFinal = 4
};

// When log packets are created they must not prepare their parameters, because it is not ensured
// that a session with a valid time source is available until the dictionary is requested by the log
// writer. Instead parameters should be collected dynamically in the
// `dictionaryWithSessionId:paketSequenceNumber:` method.
@protocol IMUTLibLogPacket

- (IMUTLibLogPacketType)logPacketType;

- (NSDictionary *)dictionaryWithSequence:(unsigned long)sequence;

- (void)setAdditionalParameters:(NSDictionary *)parameters;

@end
