#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "IMUTLibSourceEvent.h"

@interface IMUTLibHeadingChangeEvent : NSObject <IMUTLibSourceEvent>

- (instancetype)initWithHeading:(CLHeading *)heading;

- (CLHeading *)heading;

@end
