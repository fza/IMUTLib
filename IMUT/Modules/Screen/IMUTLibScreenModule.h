#import <Foundation/Foundation.h>
#import "IMUTLibTimeSource.h"
#import "IMUTLibAbstractModule.h"

@interface IMUTLibScreenModule : IMUTLibAbstractModule <IMUTLibTimeSource>

@property(nonatomic, readwrite, weak) id <IMUTLibTimeSourceDelegate> timeSourceDelegate;

@end
