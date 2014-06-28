#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "IMUTLibEventAggregator.h"
#import "IMUTLibAbstractModule.h"

@interface IMUTLibHeadingModule : IMUTLibAbstractModule <IMUTLibEventAggregator, CLLocationManagerDelegate>

@end
