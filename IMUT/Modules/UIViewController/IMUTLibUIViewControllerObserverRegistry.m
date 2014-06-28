#import "IMUTLibUIViewControllerObserverRegistry.h"

@implementation IMUTLibUIViewControllerObserverRegistry {
    NSMutableDictionary *_registry;
}

SINGLETON

- (instancetype)init {
    if (self = [super init]) {
        _registry = [NSMutableDictionary dictionary];
    }

    return self;
}

- (void)registerObserverClass:(Class <IMUTLibUIViewControllerObserver>)observerClass forUIClass:(Class)uiClass {
    NSString *uiClassName = NSStringFromClass(uiClass);

    NSAssert(!_registry[uiClassName], @"An observer for UI class \"%@\" is already present.", uiClassName);

    _registry[uiClassName] = observerClass;
}

- (void)invokeObserverWithObject:(id)object {
    Class uiClass = [object class];
    NSString *uiClassName = NSStringFromClass(uiClass);
    Class <IMUTLibUIViewControllerObserver> observerClass = _registry[uiClassName];

//    NSAssert(observerClass, @"An observer for UI class \"%@\" is not available.", uiClassName);
    if (observerClass) {
        [observerClass observe:object];
    }
}

@end
