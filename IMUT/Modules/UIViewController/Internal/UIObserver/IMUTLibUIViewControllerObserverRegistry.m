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

- (BOOL)invokeObserverWithObject:(id)object {
    for (NSString *uiClassName in [_registry allKeys]) {
        if ([object isKindOfClass:NSClassFromString(uiClassName)]) {
            [_registry[uiClassName] observe:object];

            return YES;
        }
    }

    return NO;
}

@end
