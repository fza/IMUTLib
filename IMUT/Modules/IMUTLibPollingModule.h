#import <Foundation/Foundation.h>

#import "IMUTLibModule.h"

// Base class for modules that want to be notified at the beginning of each
// runloop call of the synchronizer
@interface IMUTLibPollingModule : IMUTLibModule

- (void)poll;

@end
