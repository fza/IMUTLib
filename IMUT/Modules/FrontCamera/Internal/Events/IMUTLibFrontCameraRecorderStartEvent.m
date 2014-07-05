#import "IMUTLibFrontCameraRecorderStartEvent.h"
#import "IMUTLibFrontCameraModuleConstants.h"

@implementation IMUTLibFrontCameraRecorderStartEvent

#pragma mark IMUTLibSourceEvent protocol

- (NSString *)eventName {
    return kIMUTLibFrontCameraModuleRecorderStartEvent;
}

- (NSDictionary *)parameters {
    return nil;
}

@end
