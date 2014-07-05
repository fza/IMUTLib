#import <Foundation/Foundation.h>

#import "Macros.h"
#import "IMUTLibSourceEvent.h"

@interface IMUTLibSourceEventCollection : NSObject

SINGLETON_INTERFACE

- (void)addSourceEvent:(NSObject <IMUTLibSourceEvent> *)sourceEvent now:(BOOL)now;

- (void)addSourceEvent:(NSObject <IMUTLibSourceEvent> *)sourceEvent;

@end
