#import "IMUTLibMain+Internal.h"
#import "IMUTLibSyncLogPacket.h"
#import "IMUTLibUtil.h"

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

- (NSDictionary *)dictionaryWithSessionId:(NSString *)sessionId packetSequenceNumber:(unsigned long)sequenceNumber {
    NSMutableDictionary *dictionary = [self baseDictionaryWithSessionId:sessionId
                                                         sequenceNumber:sequenceNumber];

    dictionary[@"abs-time"] = [IMUTLibUtil iso8601StringFromDate:self.syncDate];

    if (self.timeSourceInfo) {
        dictionary[@"time-source"] = self.timeSourceInfo;
    }

    [dictionary addEntriesFromDictionary:_additionalParameters];

    return dictionary;
}

- (instancetype)initWithSyncDate:(NSDate *)syncDate timeSourceInfo:(NSString *)timeSourceInfo {
    if (self = [super init]) {
        self.syncDate = syncDate;
        self.timeSourceInfo = timeSourceInfo;
    }

    return self;
}

@end
