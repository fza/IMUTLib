#import <Foundation/Foundation.h>

#import "IMUTLibLogPacket.h"
#import "IMUTLibPersistableEntityBag.h"

// The events packet is the most important one as it stores the
// actual data as gathered on runtime at a specific time
@interface IMUTLibEventsLogPacket : IMUTLibLogPacket

// The delta entity bag containing the filtered and prepared delta entities
// ready to be persisted
@property(nonatomic, readonly, retain) IMUTLibPersistableEntityBag *entityBag;

@property(nonatomic, readonly, assign) NSTimeInterval relativeTime;

+ (instancetype)packetWithDeltaEntityBag:(IMUTLibPersistableEntityBag *)deltaEntityBag
                                 forTime:(NSTimeInterval)time;

// Convenience method to merge in logPackets late
- (void)mergeWith:(IMUTLibEventsLogPacket *)logPacket;

@end
