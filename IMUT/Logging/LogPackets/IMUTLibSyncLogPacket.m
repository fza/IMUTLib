#import "IMUTLibMain+Internal.h"
#import "IMUTLibSyncLogPacket.h"
#import "IMUTLibFunctions.h"

static NSString *kParamAbsoluteDateTime = @"abs-date-time";
static NSString *kParamTimeSourceInfo = @"time-source";

@interface IMUTLibSyncLogPacket ()

@property(nonatomic, readwrite, retain) NSDate *syncDate;
@property(nonatomic, readwrite, retain) NSString *timeSourceInfo;

- (instancetype)initWithSyncDate:(NSDate *)startDate timeSourceInfo:(NSString *)timeSourceInfo;

@end

@implementation IMUTLibSyncLogPacket

DESIGNATED_INIT

- (IMUTLibLogPacketType)logPacketType {
    return IMUTLibLogPacketTypeSync;
}

+ (instancetype)packetWithSyncDate:(NSDate *)startDate timeSourceInfo:(NSString *)timeSourceInfo {
    return [[self alloc] initWithSyncDate:startDate timeSourceInfo:timeSourceInfo];
}

- (NSDictionary *)parameters {
    return @{
        kParamAbsoluteDateTime : iso8601StringFromDate(self.syncDate),
        kParamTimeSourceInfo : self.timeSourceInfo
    };
}

#pragma mark Private

- (instancetype)initWithSyncDate:(NSDate *)syncDate timeSourceInfo:(NSString *)timeSourceInfo {
    if (self = [super init]) {
        self.syncDate = syncDate;
        self.timeSourceInfo = timeSourceInfo;
    }

    return self;
}

@end
