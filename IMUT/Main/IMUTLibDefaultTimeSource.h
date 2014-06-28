#import <Foundation/Foundation.h>
#import "IMUTLibTimeSource.h"

NSUInteger IMUTLibDefaultTimeSourcePreference;

@interface IMUTLibDefaultTimeSource : NSObject <IMUTLibTimeSource>

@property(nonatomic, readwrite, weak) id <IMUTLibTimeSourceDelegate> timeSourceDelegate;

@end
