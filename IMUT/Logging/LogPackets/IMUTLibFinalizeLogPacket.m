#import "IMUTLibFinalizeLogPacket.h"
#import "Macros.h"

static NSString *kParamSessionDuration = @"session-duration";
static NSString *kParamEventCount = @"event-count";

@interface IMUTLibFinalizeLogPacket ()

@property(nonatomic, readwrite, assign) NSTimeInterval sessionDuration;
@property(nonatomic, readwrite, assign) unsigned long eventCount;

- (instancetype)initWithSessionDuration:(NSTimeInterval)startDate eventCount:(unsigned long)eventCount;

@end

@implementation IMUTLibFinalizeLogPacket

DESIGNATED_INIT

- (IMUTLibLogPacketType)logPacketType {
    return IMUTLibLogPacketTypeFinalize;
}

+ (instancetype)packetWithSessionDuration:(NSTimeInterval)sessionDuration eventCount:(unsigned long)eventCount {
    return [[self alloc] initWithSessionDuration:sessionDuration
                                      eventCount:eventCount];
}

- (NSDictionary *)parameters {
    return @{
        kParamSessionDuration : @(round(self.sessionDuration * 100.0) / 100.0),
        kParamEventCount : @(self.eventCount)
    };
}

#pragma mark Private

- (instancetype)initWithSessionDuration:(NSTimeInterval)sessionDuration eventCount:(unsigned long)eventCount {
    if (self = [super init]) {
        self.sessionDuration = sessionDuration;
        self.eventCount = eventCount;
    }

    return self;
}

@end
