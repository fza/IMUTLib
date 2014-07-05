#import "IMUTLibSyncLogPacket.h"
#import "IMUTLibSession.h"
#import "IMUTLibFunctions.h"
#import "IMUTLibMain+Internal.h"
#import "IMUTLibConstants.h"

@implementation IMUTLibSyncLogPacket

- (IMUTLibLogPacketType)logPacketType {
    return IMUTLibLogPacketTypeSync;
}

- (NSDictionary *)parameters {
    IMUTLibSession *session = [IMUTLibMain imut].session;

    return @{
        kParamAbsoluteDateTime : iso8601StringFromDate(session.startDate),
        kParamTimebaseInfo : [session timerInfo]
    };
}

@end
