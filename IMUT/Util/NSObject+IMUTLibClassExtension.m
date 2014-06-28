#import <objc/runtime.h>
#import "NSObject+IMUTLibClassExtension.h"
#import "Macros.h"

void integrateClassMethod(Class targetClass, Class sourceClass, SEL targetSelector, SEL sourceSelector, SEL originalSelector, IMUTLibMethodIntegrationStatus *status);

@implementation NSObject (IMUTLibClassExtension)

+ (void)__IMUT_integrateMethodFromSourceClass:(Class)sourceClass withSourceSelector:(SEL)sourceSelector {
    integrateClassMethod(self, sourceClass, sourceSelector, NULL, NULL, NULL);
}

+ (void)__IMUT_integrateMethodFromSourceClass:(Class)sourceClass withSourceSelector:(SEL)sourceSelector status:(IMUTLibMethodIntegrationStatus *)status {
    integrateClassMethod(self, sourceClass, sourceSelector, NULL, NULL, status);
}

+ (void)__IMUT_integrateMethodFromSourceClass:(Class)sourceClass withSourceSelector:(SEL)sourceSelector byRenamingOriginalSelectorToSelector:(SEL)originalSelector status:(IMUTLibMethodIntegrationStatus *)status {
    integrateClassMethod(self, sourceClass, sourceSelector, NULL, originalSelector, status);
}

+ (void)__IMUT_integrateMethodFromSourceClass:(Class)sourceClass withSourceSelector:(SEL)sourceSelector forTargetSelector:(SEL)targetSelector byRenamingItToOriginalSelector:(SEL)originalSelector status:(IMUTLibMethodIntegrationStatus *)status {
    integrateClassMethod(self, sourceClass, targetSelector, sourceSelector, originalSelector, status);
}

@end

/*!
Integrate or swap instace methods of a class at runtime

(1) A: the method implementation of `sourceSelector` found in `sourceClass`
(2) B: the method implementation of `targetSelector` found in `targetClass`
(3) If B is available:
     Rename selector B by prepending the string "original_" or by using `originalSelector` if present
(4) In the target class set A with the method implementation of B

@param Class targetClass The target class on which to perform integration
@param Class sourceClass The source class to search for the sourceSelector
@param SEL targetSelector The selector on the target class to override
@param SEL|NULL sourceSelector The selector on the source class to use as stand in for the target selector. Pass NULL if it is the same as targetSelector.
@param SEL|NULL originalSelector The selector to use for the movement of the original selector on the target class. Pass NULL to use a generated selector in the form "original_my:selector:".
@param IMUTLibMethodIntegrationStatus|NULL *status Pointer to variable containing status constant.
@param BOOL assert Wether to throw an exception if the operation failed.

@return BOOL Wether the operation was successful
 */
void integrateClassMethod(Class targetClass, Class sourceClass, SEL targetSelector, SEL sourceSelector, SEL originalSelector, IMUTLibMethodIntegrationStatus *status) {
    if (!sourceSelector) {
        sourceSelector = targetSelector;
    }

    NSCAssert(targetClass, @"Target class not set.");
    NSCAssert(sourceClass, @"Source class not set.");
    NSCAssert(targetSelector, @"Target selector not set.");
    NSCAssert(class_respondsToSelector(sourceClass, sourceSelector), @"Unknown source method.");

    IMUTLibMethodIntegrationStatus _status;
    Method sourceMethod = class_getInstanceMethod(sourceClass, sourceSelector);
    IMP sourceMethodImplementation = [sourceClass instanceMethodForSelector:sourceSelector];
    const char *sourceMethodEncoding = method_getTypeEncoding(sourceMethod);

    IMUTLogDebugC(@"source class/selector: %@ / %@", sourceClass, NSStringFromSelector(sourceSelector));
    IMUTLogDebugC(@" --> target class/selector: %@ / %@", targetClass, NSStringFromSelector(targetSelector));

    if (class_respondsToSelector(targetClass, targetSelector)) {
        Method targetMethod = class_getInstanceMethod(targetClass, targetSelector);
        IMP targetMethodImplementation = [targetClass instanceMethodForSelector:targetSelector];
        const char *targetMethodEncoding = method_getTypeEncoding(targetMethod);

        NSCAssert(strcmp(sourceMethodEncoding, targetMethodEncoding) == 0,
                @"Unable to replace selector \"%@\" in class \"%@\" as the method signatures differ.",
                NSStringFromSelector(targetSelector),
                NSStringFromClass(targetClass)
            );

        if (!originalSelector) {
            originalSelector = NSSelectorFromString([@"original_" stringByAppendingString:NSStringFromSelector(targetSelector)]);
        }

        NSCAssert(!class_respondsToSelector(targetClass, originalSelector),
                @"Unable to replace selector \"%@\" in class \"%@\" as the future original selector \"%@\" is already present.",
                NSStringFromSelector(targetSelector),
                NSStringFromClass(targetClass),
                NSStringFromSelector(originalSelector)
            );

        IMUTLogDebugC(@" --> target class/original selector: %@ / %@", targetClass, NSStringFromSelector(targetSelector));

        class_addMethod(targetClass, originalSelector, targetMethodImplementation, targetMethodEncoding);
        class_replaceMethod(targetClass, targetSelector, sourceMethodImplementation, sourceMethodEncoding);
        _status = IMUTLibMethodIntegrationByRenamingOriginalSelector;
    } else {
        class_addMethod(targetClass, targetSelector, sourceMethodImplementation, sourceMethodEncoding);
        _status = IMUTLibMethodIntegrationByAddingMethodWithoutOriginalImplementation;
    }

    if (status != NULL) {
        *status = _status;
    }
}
