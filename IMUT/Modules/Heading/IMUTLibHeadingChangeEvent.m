#import "IMUTLibHeadingChangeEvent.h"
#import "IMUTLibHeadingModuleConstants.h"

@implementation IMUTLibHeadingChangeEvent {
    CLHeading *_heading;
}

- (instancetype)initWithHeading:(CLHeading *)heading {
    if (self = [super init]) {
        _heading = heading;

        return self;
    }

    return nil;
}

- (CLHeading *)heading {
    return _heading;
}

#pragma mark IMUTLibSourceEvent protocol

- (NSString *)eventName {
    return kIMUTLibHeadingChangeEvent;
}

- (NSDictionary *)parameters {
    return @{
        kIMUTLibHeadingChangeEventParamHeading : [NSNumber numberWithDouble:_heading.magneticHeading]
    };
}

@end
