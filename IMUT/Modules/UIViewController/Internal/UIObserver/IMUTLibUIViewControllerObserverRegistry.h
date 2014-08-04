#import <Foundation/Foundation.h>

#import "Macros.h"
#import "IMUTLibUIViewControllerObserver.h"

@interface IMUTLibUIViewControllerObserverRegistry : NSObject

SINGLETON_INTERFACE

- (void)registerObserverClass:(Class <IMUTLibUIViewControllerObserver>)observerClass forUIClass:(Class)uiClass;

- (BOOL)invokeObserverWithObject:(id)object;

@end
