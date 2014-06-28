#import <Foundation/Foundation.h>
#import "IMUTLibUIViewControllerObserver.h"
#import "Macros.h"

@interface IMUTLibUIViewControllerObserverRegistry : NSObject

SINGLETON_INTERFACE

- (void)registerObserverClass:(Class <IMUTLibUIViewControllerObserver>)observerClass forUIClass:(Class)uiClass;

- (void)invokeObserverWithObject:(id)object;

@end
