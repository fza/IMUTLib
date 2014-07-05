#import <Foundation/Foundation.h>

#import "IMUTLibPersistableEntity.h"

@interface IMUTLibPersistableEntity (Internal)

+ (NSString *)stringFromEntityType:(IMUTLibPersistableEntityType)entityType;

+ (NSString *)stringFromEntityMarking:(IMUTLibPersistableEntityMarking)entityMarking;

- (NSString *)entityTypeString;

- (NSString *)entityMarkingString;

@end
