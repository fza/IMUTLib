#import "IMUTLibFinalLogPacket.h"
#import "IMUTLibEventSynchronizer.h"
#import "IMUTLibMain+Internal.h"

static NSString *kParamSessionDuration = @"session-duration";
static NSString *kParamEventCount = @"event-count";

@implementation IMUTLibFinalLogPacket

- (IMUTLibLogPacketType)logPacketType {
    return IMUTLibLogPacketTypeFinal;
}

- (NSDictionary *)parameters {
    IMUTLibEventSynchronizer *synchronizer = [IMUTLibEventSynchronizer sharedInstance];
    NSTimeInterval sessionDuration = [synchronizer alignTimeInterval:([IMUTLibMain imut].session.duration)];

    return @{
        kParamSessionDuration : @(round(sessionDuration * 100.0) / 100.0),
        kParamEventCount : @(synchronizer.eventCount)
    };
}

@end
