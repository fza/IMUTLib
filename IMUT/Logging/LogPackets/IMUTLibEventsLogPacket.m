#import "IMUTLibEventsLogPacket.h"
#import "IMUTLibDeltaEntity+Internal.h"
#import "Macros.h"

static NSString *kParamRelativeTime = @"rel-time";
static NSString *kParamEvents = @"events";
static NSString *kParamEvent = @"event";
static NSString *kParamType = @"type";
static NSString *kParamParams = @"params";

@interface IMUTLibEventsLogPacket ()

@property(nonatomic, readwrite, retain) IMUTLibDeltaEntityBag *deltaEntityBag;
@property(nonatomic, readwrite, assign) NSTimeInterval relativeTime;

- (instancetype)initWithDeltaEntityBag:(IMUTLibDeltaEntityBag *)deltaEntityBag timeIntervalSinceStart:(NSTimeInterval)timeInterval;

@end

@implementation IMUTLibEventsLogPacket {
    IMUTLibDeltaEntityBag *_deltaEntityBag;
}

DESIGNATED_INIT

- (IMUTLibLogPacketType)logPacketType {
    return IMUTLibLogPacketTypeEvents;
}

+ (instancetype)packetWithDeltaEntityBag:(IMUTLibDeltaEntityBag *)deltaEntityBag timeIntervalSinceStart:(NSTimeInterval)timeInterval {
    return [[self alloc] initWithDeltaEntityBag:deltaEntityBag
                         timeIntervalSinceStart:(NSTimeInterval) timeInterval];
}

- (void)mergeIn:(IMUTLibEventsLogPacket *)logPacket {
    [_deltaEntityBag mergeWithBag:logPacket.deltaEntityBag];
}

- (NSDictionary *)parameters {
    NSMutableArray *events = [NSMutableArray array];
    for (IMUTLibDeltaEntity *deltaEntity in self.deltaEntityBag.all) {
        [events addObject:@{
            kParamEvent : deltaEntity.eventName,
            kParamType : [deltaEntity entityTypeString],
            kParamParams : deltaEntity.parameters
        }];
    }

    return @{
        kParamRelativeTime : @(round(self.relativeTime * 100.0) / 100.0),
        kParamEvents : events
    };
}

#pragma mark Private

- (instancetype)initWithDeltaEntityBag:(IMUTLibDeltaEntityBag *)deltaEntityBag timeIntervalSinceStart:(NSTimeInterval)timeInterval {
    if (self = [super init]) {
        self.deltaEntityBag = deltaEntityBag;
        self.relativeTime = timeInterval;
    }

    return self;
}

@end
