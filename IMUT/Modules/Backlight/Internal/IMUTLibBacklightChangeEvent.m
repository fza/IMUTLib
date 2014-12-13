#import "IMUTLibBacklightChangeEvent.h"
#import "IMUTLibBacklightModuleConstants.h"

@implementation IMUTLibBacklightChangeEvent {
    CGFloat _brightness;
}

- (instancetype)initWithBrightness:(CGFloat)brightess {
    if (self = [super init]) {
        _brightness = brightess;

        return self;
    }

    return nil;
}

- (CGFloat)brightness {
    return _brightness;
}

#pragma mark IMUTLibSourceEvent protocol

- (NSString *)eventName {
    return kIMUTLibBacklightChangeEvent;
}

- (NSDictionary *)parameters {
    return @{
        kIMUTLibBacklightChangeEventParamVal : @(round(_brightness * 100.0) / 100.0)
    };
}

@end
