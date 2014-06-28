#import <CoreLocation/CoreLocation.h>
#import "IMUTLibLocationChangeEvent.h"
#import "IMUTLibLocationModuleConstants.h"

@implementation IMUTLibLocationChangeEvent {
    CLLocation *_location;
}

- (instancetype)initWithLocation:(CLLocation *)location {
    if (self = [super init]) {
        _location = location;

        return self;
    }

    return nil;
}

- (CLLocation *)location {
    return _location;
}

#pragma mark IMUTLibSourceEvent protocol

- (NSString *)eventName {
    return kIMUTLibLocationChangeEvent;
}

- (NSDictionary *)parameters {
    return @{
        kIMUTLibLocationChangeEventParamLongitude : [NSNumber numberWithDouble:_location.coordinate.longitude],
        kIMUTLibLocationChangeEventParamLatitude : [NSNumber numberWithDouble:_location.coordinate.latitude],
    };
}

@end
