#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, IMUTLibMethodIntegrationStatus) {
    IMUTLibMethodIntegrationByAddingMethodWithoutOriginalImplementation = 1,
    IMUTLibMethodIntegrationByRenamingOriginalSelector = 2
};

@interface NSObject (IMUTLibClassExtension)

+ (void)__IMUT_integrateMethodFromSourceClass:(Class)sourceClass
                           withSourceSelector:(SEL)sourceSelector;

+ (void)__IMUT_integrateMethodFromSourceClass:(Class)sourceClass
                           withSourceSelector:(SEL)sourceSelector
                                       status:(IMUTLibMethodIntegrationStatus *)status;

+ (void)__IMUT_integrateMethodFromSourceClass:(Class)sourceClass
                           withSourceSelector:(SEL)sourceSelector
         byRenamingOriginalSelectorToSelector:(SEL)originalSelector
                                       status:(IMUTLibMethodIntegrationStatus *)status;


+ (void)__IMUT_integrateMethodFromSourceClass:(Class)sourceClass
                           withSourceSelector:(SEL)sourceSelector
                            forTargetSelector:(SEL)targetSelector
               byRenamingItToOriginalSelector:(SEL)originalSelector
                                       status:(IMUTLibMethodIntegrationStatus *)status;

@end
