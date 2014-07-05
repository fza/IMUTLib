#import "IMUTLibPersistableEntity+Internal.h"
#import "IMUTLibConstants.h"

@implementation IMUTLibPersistableEntity (Internal)

+ (NSString *)stringFromEntityType:(IMUTLibPersistableEntityType)entityType {
    switch (entityType) {
        case IMUTLibPersistableEntityTypeAbsolute:
            return kIMUTLibPersistableEntityTypeAbsolute;

        case IMUTLibPersistableEntityTypeDelta:
            return kIMUTLibPersistableEntityTypeDelta;

        case IMUTLibPersistableEntityTypeStatus:
            return kIMUTLibPersistableEntityTypeStatus;

        case IMUTLibPersistableEntityTypeMixed:
            return kIMUTLibPersistableEntityTypeMixed;

        case IMUTLibPersistableEntityTypeOther:
            return kIMUTLibPersistableEntityTypeOther;

        default:
            return kIMUTLibPersistableEntityTypeUnknown;
    }
}

+ (NSString *)stringFromEntityMarking:(IMUTLibPersistableEntityMarking)entityMarking {
    switch (entityMarking) {
        case IMUTLibPersistableEntityMarkInitial:
            return kEntityMarkInitial;

        case IMUTLibPersistableEntityMarkFinal:
            return kEntityMarkFinal;

        default:
            return nil;
    }
}

- (NSString *)entityTypeString {
    return [[self class] stringFromEntityType:self.entityType];
}

- (NSString *)entityMarkingString {
    return [[self class] stringFromEntityMarking:self.entityMarking];
}

@end
