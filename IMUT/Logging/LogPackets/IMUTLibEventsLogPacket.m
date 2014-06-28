#import "IMUTLibEventsLogPacket.h"
#import "IMUTLibDeltaEntity+Internal.h"
#import "Macros.h"

@interface IMUTLibEventsLogPacket ()

@property(nonatomic, readwrite, retain) IMUTLibDeltaEntityCache *deltaEntityCache;
@property(nonatomic, readwrite, assign) NSTimeInterval relativeTime;

- (instancetype)initWithDeltaEntityCache:(IMUTLibDeltaEntityCache *)deltaEntityCache timeIntervalSinceStart:(NSTimeInterval)timeInterval;

@end

@implementation IMUTLibEventsLogPacket

DESIGNATED_INIT

- (IMUTLibLogPacketType)logPacketType {
    return IMUTLibLogPacketTypeEvents;
}

+ (instancetype)packetWithDeltaEntityCache:(IMUTLibDeltaEntityCache *)deltaEntityCache timeIntervalSinceStart:(NSTimeInterval)timeInterval {
    return [[self alloc] initWithDeltaEntityCache:deltaEntityCache
                           timeIntervalSinceStart:(NSTimeInterval) timeInterval];
}

- (instancetype)initWithDeltaEntityCache:(IMUTLibDeltaEntityCache *)deltaEntityCache timeIntervalSinceStart:(NSTimeInterval)timeInterval {
    if (self = [super init]) {
        self.deltaEntityCache = deltaEntityCache;
        self.relativeTime = timeInterval;
    }

    return self;
}

- (NSDictionary *)dictionaryWithSessionId:(NSString *)sessionId packetSequenceNumber:(unsigned long)sequenceNumber {
    NSMutableDictionary *dictionary = [self baseDictionaryWithSessionId:sessionId
                                                         sequenceNumber:sequenceNumber];

    dictionary[@"rel-time"] = [NSNumber numberWithDouble:round(self.relativeTime * 100.0) / 100.0];

    NSMutableArray *payload = [NSMutableArray array];
    for (IMUTLibDeltaEntity *deltaEntity in self.deltaEntityCache.all) {
        [payload addObject:@{
            @"event" : deltaEntity.eventName,
            @"type" : [deltaEntity entityTypeString],
            @"params" : deltaEntity.parameters
        }];
    }
    dictionary[@"payload"] = payload;

    [dictionary addEntriesFromDictionary:_additionalParameters];

    return dictionary;
}

@end
