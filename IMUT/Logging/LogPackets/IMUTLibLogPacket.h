#import <Foundation/Foundation.h>

#import "IMUTLibPersistableEntity+Internal.h"
#import "IMUTLibMain+Internal.h"

// These are the currently implementd log packet types
typedef NS_ENUM(NSUInteger, IMUTLibLogPacketType) {
    IMUTLibLogPacketTypeSessionInit = 1, // Always first in log file
    IMUTLibLogPacketTypeSync = 2,        // Always second in log file
    IMUTLibLogPacketTypeEvents = 3,      // Then come the events, one at a time
    IMUTLibLogPacketTypeFinal = 4        // The final packet stores some statistics about the session
};

// The abstract log packet class eases the creation and querying of
// log packets as concrete subclasses only need to override the
// `parameters` method and produce the specific data. The abstract
// log packet is responsible for the heavy lifting
@interface IMUTLibLogPacket : NSObject {
    NSMutableDictionary *_additionalParameters;
}

// One of four basic log packet types
- (IMUTLibLogPacketType)logPacketType;

// Used by the log writer to get an encodable dictionary. The only thing the log writer keeps
// track of is the ever increasing sequence number for each packet
- (NSDictionary *)dictionaryWithSequence:(unsigned long)sequence;

// Callers may set any additional parameters to be merged in
- (void)setAdditionalParameters:(NSDictionary *)parameters;

// MUST BE OVERRIDEN BY CONCRETE SUBCLASS
- (NSDictionary *)parameters;

// Returns a static NSString object reference with the concrete log packet
// type. This is created by the abstract log packet class based on the
// outputs of the `logPacketType` method of the concrete subclass
- (NSString *)stringFromLogPacketType:(IMUTLibLogPacketType)logPacketType;

@end
