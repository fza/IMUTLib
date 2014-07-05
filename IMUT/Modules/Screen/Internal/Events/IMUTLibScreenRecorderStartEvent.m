#import "IMUTLibScreenRecorderStartEvent.h"
#import "IMUTLibScreenModuleConstants.h"

@implementation IMUTLibScreenRecorderStartEvent

#pragma mark IMUTLibSourceEvent protocol

- (NSString *)eventName {
    return kIMUTLibScreenModuleRecorderStartEvent;
}

- (NSDictionary *)parameters {
    return nil;
}

@end
