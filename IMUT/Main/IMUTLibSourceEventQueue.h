#import <Foundation/Foundation.h>
#import "IMUTLibSourceEvent.h"
#import "Macros.h"

@interface IMUTLibSourceEventQueue : NSObject

SINGLETON_INTERFACE

- (void)enqueueSourceEvent:(id <IMUTLibSourceEvent>)sourceEvent;

@end
