#import "IMUTLibUIViewControllerModule+SourceEventGeneration.h"
#import "IMUTLibWeakWrappedObject.h"
#import "IMUTLibSourceEventQueue.h"
#import "IMUTLibUIViewControllerModuleConstants.h"
#import "IMUTLibUIViewControllerObserverRegistry.h"
#import "IMUTLibUtil.h"

static IMUTLibWeakWrappedObject *wrappedFrontMostViewController;
static int maxViewControllerNestingLevel = 25;
static BOOL haveHierarchy = NO;
static BOOL stopped = YES;

@interface IMUTLibUIViewControllerModule (SourceEventGenerationInternal)

- (NSMutableArray *)mutableObjectHierarchy;

- (void)setFrontMostViewControllerWithWrapper:(IMUTLibWeakWrappedObject *)frontMostViewController;

- (void)rebuildEntireObjectHierarchy;

- (void)resetObjectHierarchy;

- (void)inspectObject:(id)object;

- (void)doInspectObject:(id)object;

- (void)removeObjectsAtAndBelowLevel:(NSUInteger)level;

- (void)ensureObservingObject:(id)object;

- (NSString *)childKeyPathForObject:(id)object;

- (id)childObjectForObject:(id)object;

- (NSUInteger)indexForObject:(id)searchObject;

@end

@implementation IMUTLibUIViewControllerModule (SourceEventGenerationInternal)

- (NSMutableArray *)mutableObjectHierarchy {
    static NSMutableArray *objectHierarchy;

    if (!objectHierarchy) {
        objectHierarchy = [NSMutableArray array];
    }

    return objectHierarchy;
}

- (void)setFrontMostViewControllerWithWrapper:(IMUTLibWeakWrappedObject *)wrappedViewController {
    @synchronized (self) {
        if (!wrappedViewController) {
            wrappedFrontMostViewController = nil;

            return;
        }

        __strong UIViewController *oldController = wrappedFrontMostViewController.wrappedObject;
        __strong UIViewController *newController = wrappedViewController.wrappedObject;

        if (newController && (!oldController || oldController != newController)) {
            [IMUTLibUtil postNotificationOnMainThreadWithNotificationName:IMUTLibFrontMostViewControllerDidChangeNotification
                                                                   object:newController
                                                            waitUntilDone:NO];

            IMUTLogDebug(@"new vc: %@", newController);

            wrappedFrontMostViewController = wrappedViewController;

            [[IMUTLibSourceEventQueue sharedInstance] enqueueSourceEvent:[self sourceEventWithViewController:newController]];
        }
    }
}

- (void)rebuildEntireObjectHierarchy {
    @synchronized (self) {
        [self resetObjectHierarchy];

        // The main UIApplication object is the root object
        [self inspectObject:[UIApplication sharedApplication]];
    }
}

- (void)resetObjectHierarchy {
    @synchronized (self) {
        [self setFrontMostViewControllerWithWrapper:nil];
        [self removeObjectsAtAndBelowLevel:0];

        haveHierarchy = NO;
    }
}

- (void)inspectObject:(id)object {
    if (!object) {
        return;
    }

    @synchronized (self) {
        [self performSelectorOnMainThread:@selector(doInspectObject:) withObject:object waitUntilDone:NO];
    }
}

- (void)doInspectObject:(__strong id)object {
    NSMutableArray *objectHierarchy = [self mutableObjectHierarchy];
    __strong id childObject;
    IMUTLibWeakWrappedObject *objectWrapper;
    NSUInteger nestingLevel = objectHierarchy.count;

    @synchronized (self) {
        if (nestingLevel != 0) {
            NSUInteger index = [self indexForObject:object];

            if (index == NSNotFound) {
                return;
            }

            [self removeObjectsAtAndBelowLevel:index];
            nestingLevel = objectHierarchy.count;
        }

        while (true) {
            [self ensureObservingObject:object];

            objectWrapper = [IMUTLibWeakWrappedObject wrapperForObject:object];
            [objectHierarchy addObject:objectWrapper];
            childObject = [self childObjectForObject:object];

            if (!childObject) {
                if ([object isKindOfClass:[UIViewController class]]) {
                    [self setFrontMostViewControllerWithWrapper:objectWrapper];
                }

                break;
            }

            object = childObject;
            nestingLevel++;

            if (nestingLevel > maxViewControllerNestingLevel) {
                break;
            }
        }

        haveHierarchy = YES;
    }
}

- (void)removeObjectsAtAndBelowLevel:(NSUInteger)level {
    NSMutableArray *objectHierarchy = [self mutableObjectHierarchy];
    NSUInteger hierarchyNestingLevel = objectHierarchy.count;

    if (level > 0 && level <= hierarchyNestingLevel) {
        [objectHierarchy removeObjectsInRange:NSMakeRange((NSUInteger) level, hierarchyNestingLevel - level)];
    }
}

- (void)ensureObservingObject:(id)object {
    [[IMUTLibUIViewControllerObserverRegistry sharedInstance] invokeObserverWithObject:object];
}

- (NSString *)childKeyPathForObject:(__strong id)object {
    static NSString *uiApplicationChildKeyPath = @"keyWindow";
    static NSString *uiWindowChildKeyPath = @"rootViewController";
    static NSString *uiNavigationControllerChildKeyPath = @"visibleViewController";
    static NSString *uiTabBarControllerChildKeyPath = @"selectedViewController";
    static NSString *uiViewControllerChildKeyPath = @"presentedViewController";

    if ([object isKindOfClass:[UIApplication class]]) {
        return uiApplicationChildKeyPath;
    } else if ([object isKindOfClass:[UIWindow class]]) {
        return uiWindowChildKeyPath;
    } else if ([object isKindOfClass:[UINavigationController class]]) {
        return uiNavigationControllerChildKeyPath;
    } else if ([object isKindOfClass:[UITabBarController class]]) {
        return uiTabBarControllerChildKeyPath;
    }

    return uiViewControllerChildKeyPath;
}

- (id)childObjectForObject:(__strong id)object {
    __strong id childObject;
    NSString *childObjectKeyPath = [self childKeyPathForObject:object];

    if (childObjectKeyPath) {
        SEL propertySelector = NSSelectorFromString(childObjectKeyPath);
        id (*func)(id, SEL) = (void *) [object methodForSelector:propertySelector];
        childObject = func(object, propertySelector);
    }

    return childObject;
}

- (NSUInteger)indexForObject:(__strong id)searchObject {
    __block NSUInteger foundAtIndex = NSNotFound;
    [[self mutableObjectHierarchy] enumerateObjectsUsingBlock:^(IMUTLibWeakWrappedObject *objectWrapper, NSUInteger index, BOOL *stop){
        __strong id wrappedObject = objectWrapper.wrappedObject;

        if (wrappedObject && searchObject == wrappedObject) {
            foundAtIndex = index;
            *stop = YES;
        }
    }];

    return foundAtIndex;
}

@end

@implementation IMUTLibUIViewControllerModule (SourceEventGeneration)

- (void)startSourceEventGeneration {
    @synchronized (self) {
        stopped = NO;
        [self rebuildEntireObjectHierarchy];
    }
}

- (void)stopSourceEventGeneration {
    @synchronized (self) {
        stopped = YES;
        [self resetObjectHierarchy];
    }
}

- (void)inspectViewController:(UIViewController *)viewController {
    @synchronized (self) {
        if (!stopped) {
            [self inspectObject:viewController];
        }
    }
}

- (void)ensureHierarchyAvailable {
    @synchronized (self) {
        if (!haveHierarchy) {
            [self rebuildEntireObjectHierarchy];
        }
    }
}

- (NSArray *)objectHierarchy {
    return [[self mutableObjectHierarchy] copy];
}

- (UIViewController *)frontMostViewController {
    return [wrappedFrontMostViewController wrappedObject];
}

@end
