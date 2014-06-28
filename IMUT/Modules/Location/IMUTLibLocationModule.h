#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "IMUTLibEventAggregator.h"
#import "IMUTLibAbstractModule.h"

@interface IMUTLibLocationModule : IMUTLibAbstractModule <IMUTLibEventAggregator, CLLocationManagerDelegate>

@end
