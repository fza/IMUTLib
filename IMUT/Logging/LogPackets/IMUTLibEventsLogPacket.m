#import "IMUTLibEventsLogPacket.h"
#import "Macros.h"
#import "IMUTLibConstants.h"

static NSString *kParamRelativeTime = @"rel-time";
static NSString *kParamEvents = @"events";
static NSString *kParamEvent = @"event";
static NSString *kParamType = @"type";
static NSString *kParamParams = @"params";

@interface IMUTLibEventsLogPacket ()

- (instancetype)initWithEntityBag:(IMUTLibPersistableEntityBag *)deltaEntityBag forTime:(NSTimeInterval)time;

@end

@implementation IMUTLibEventsLogPacket

DESIGNATED_INIT

- (IMUTLibLogPacketType)logPacketType {
    return IMUTLibLogPacketTypeEvents;
}

+ (instancetype)packetWithDeltaEntityBag:(IMUTLibPersistableEntityBag *)deltaEntityBag forTime:(NSTimeInterval)time {
    return [[self alloc] initWithEntityBag:deltaEntityBag forTime:(NSTimeInterval) time];
}

- (void)mergeWith:(IMUTLibEventsLogPacket *)logPacket {
    [_entityBag mergeWithBag:logPacket.entityBag];
}

- (NSDictionary *)parameters {
    NSMutableArray *events = [NSMutableArray array];
    for (IMUTLibPersistableEntity *entity in self.entityBag.all) {
        NSMutableDictionary *event = $MD(@{
            kParamEvent : entity.eventName,
            kParamType : [entity entityTypeString]
        });

        if (entity.parameters) {
            event[kParamParams] = entity.parameters;
        }

        NSString *entityMarking = [entity entityMarkingString];
        if (entityMarking) {
            event[kEntityMarking] = entityMarking;
        }

        [events addObject:event];
    }

    return @{
        kParamRelativeTime : @(round(_relativeTime * 100.0) / 100.0),
        kParamEvents : events
    };
}

#pragma mark Private

- (instancetype)initWithEntityBag:(IMUTLibPersistableEntityBag *)deltaEntityBag forTime:(NSTimeInterval)time {
    if (self = [super init]) {
        _entityBag = deltaEntityBag;
        _relativeTime = time;
    }

    return self;
}

@end
