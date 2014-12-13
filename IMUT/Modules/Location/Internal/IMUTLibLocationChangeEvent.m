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
        kIMUTLibLocationChangeEventParamLongitude : @((double) ((int) (_location.coordinate.longitude * 100000.0)) / 100000.0),
        kIMUTLibLocationChangeEventParamLatitude : @((double) ((int) (_location.coordinate.latitude * 100000.0)) / 100000.0),
    };
}

@end
