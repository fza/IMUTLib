#import <Foundation/Foundation.h>
#import "IMUTLibAbstractLogPacket.h"
#import "IMUTLibDeltaEntityCache.h"

@interface IMUTLibEventsLogPacket : IMUTLibAbstractLogPacket

@property(nonatomic, readonly, retain) IMUTLibDeltaEntityCache *deltaEntityCache;
@property(nonatomic, readonly, assign) NSTimeInterval relativeTime;

+ (instancetype)packetWithDeltaEntityCache:(IMUTLibDeltaEntityCache *)_currentEntityCache
                    timeIntervalSinceStart:(NSTimeInterval)timeInterval;

@end
