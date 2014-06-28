#import <Foundation/Foundation.h>
#import "IMUTLibAbstractLogPacket.h"
#import "IMUTLibDeltaEntityBag.h"

@interface IMUTLibEventsLogPacket : IMUTLibAbstractLogPacket

@property(nonatomic, readonly, retain) IMUTLibDeltaEntityBag *deltaEntityBag;
@property(nonatomic, readonly, assign) NSTimeInterval relativeTime;

+ (instancetype)packetWithDeltaEntityCache:(IMUTLibDeltaEntityBag *)_currentEntityCache
                    timeIntervalSinceStart:(NSTimeInterval)timeInterval;

@end
