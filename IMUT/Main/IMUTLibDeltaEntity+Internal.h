#import <Foundation/Foundation.h>
#import "IMUTLibDeltaEntity.h"

@interface IMUTLibDeltaEntity (Internal)

+ (NSString *)stringFromEntityType:(IMUTLibDeltaEntityType)entityType;

- (NSString *)entityTypeString;

@end
