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

- (instancetype)initWithDeltaEntityCache:(IMUTLibDeltaEntityBag *)deltaEntityCache timeIntervalSinceStart:(NSTimeInterval)timeInterval;

@end

@implementation IMUTLibEventsLogPacket

DESIGNATED_INIT

- (IMUTLibLogPacketType)logPacketType {
    return IMUTLibLogPacketTypeEvents;
}

+ (instancetype)packetWithDeltaEntityCache:(IMUTLibDeltaEntityBag *)deltaEntityCache timeIntervalSinceStart:(NSTimeInterval)timeInterval {
    return [[self alloc] initWithDeltaEntityCache:deltaEntityCache
                           timeIntervalSinceStart:(NSTimeInterval) timeInterval];
}

- (NSDictionary *)parameters {
    NSMutableDictionary * dictionary = [NSMutableDictionary dictionary];

    NSMutableArray *events = [NSMutableArray array];
    for (IMUTLibDeltaEntity *deltaEntity in self.deltaEntityBag.all) {
        [events addObject:@{
            kParamEvent : deltaEntity.eventName,
            kParamType : [deltaEntity entityTypeString],
            kParamParams : deltaEntity.parameters
        }];
    }

    [dictionary addEntriesFromDictionary:@{
        kParamRelativeTime : @(round(self.relativeTime * 100.0) / 100.0),
        kParamEvents : events
    }];

    return dictionary;
}

#pragma mark Private

- (instancetype)initWithDeltaEntityCache:(IMUTLibDeltaEntityBag *)deltaEntityCache timeIntervalSinceStart:(NSTimeInterval)timeInterval {
    if (self = [super init]) {
        self.deltaEntityBag = deltaEntityCache;
        self.relativeTime = timeInterval;
    }

    return self;
}

@end
