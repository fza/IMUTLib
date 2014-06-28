#import "IMUTLibDeltaEntity+Internal.h"
#import "IMUTLibConstants.h"

@implementation IMUTLibDeltaEntity (Internal)

+ (NSString *)stringFromEntityType:(IMUTLibDeltaEntityType)entityType {
    switch (entityType) {
        case IMUTLibDeltaEntityTypeAbsolute:
            return kIMUTLibDeltaEntityTypeAbsolute;

        case IMUTLibDeltaEntityTypeDelta:
            return kIMUTLibDeltaEntityTypeDelta;

        case IMUTLibDeltaEntityTypeStatus:
            return kIMUTLibDeltaEntityTypeStatus;

        case IMUTLibDeltaEntityTypeMixed:
            return kIMUTLibDeltaEntityTypeMixed;

        case IMUTLibDeltaEntityTypeOther:
            return kIMUTLibDeltaEntityTypeOther;

        default:
            return kIMUTLibDeltaEntityTypeUnknown;
    }
}

- (NSString *)entityTypeString {
    return [[self class] stringFromEntityType:self.entityType];
}

@end
