#import "IMUTLibMain+Internal.h"
#import "IMUTLibSyncLogPacket.h"
#import "IMUTLibFunctions.h"

static NSString *kParamAbsoluteDateTime = @"abs-date-time";
static NSString *kParamTimeSourceInfo = @"time-source";

@implementation IMUTLibSyncLogPacket

- (IMUTLibLogPacketType)logPacketType {
    return IMUTLibLogPacketTypeSync;
}

- (NSDictionary *)parameters {
    IMUTLibSession *session = [IMUTLibMain imut].session;
    
    return @{
        kParamAbsoluteDateTime : iso8601StringFromDate(session.startDate),
        kParamTimeSourceInfo : [session.timeSource timeSourceInfo]
    };
}

@end
