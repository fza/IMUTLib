#import <Foundation/Foundation.h>
#import "IMUTLibAbstractLogPacket.h"

@interface IMUTLibFinalizeLogPacket : IMUTLibAbstractLogPacket

@property(nonatomic, readonly, assign) NSTimeInterval sessionDuration;
@property(nonatomic, readonly, assign) unsigned long eventCount;

+ (instancetype)packetWithSessionDuration:(NSTimeInterval)sessionDuration eventCount:(unsigned long)eventCount;

@end
