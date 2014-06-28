#import <Foundation/Foundation.h>
#import "IMUTLibAbstractLogPacket.h"

@interface IMUTLibSyncLogPacket : IMUTLibAbstractLogPacket

@property(nonatomic, readonly, retain) NSDate *syncDate;
@property(nonatomic, readonly, retain) NSString *timeSourceInfo;

+ (instancetype)packetWithSyncDate:(NSDate *)startDate timeSourceInfo:(NSString *)timeSourceInfo;

@end
