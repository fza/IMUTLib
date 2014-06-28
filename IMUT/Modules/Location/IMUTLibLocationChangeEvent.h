#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "IMUTLibSourceEvent.h"

@interface IMUTLibLocationChangeEvent : NSObject <IMUTLibSourceEvent>

- (instancetype)initWithLocation:(CLLocation *)location;

- (CLLocation *)location;

@end
