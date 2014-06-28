#import <Foundation/Foundation.h>
#import "IMUTLibSourceEvent.h"

typedef NS_ENUM(NSUInteger, IMUTLibUIViewControllerModuleClassNameRepresentation) {
    IMUTLibUIViewControllerModuleClassNameRepresentationFull = 1,
    IMUTLibUIViewControllerModuleClassNameRepresentationShort = 2
};

@interface IMUTLibUIViewControllerChangeEvent : NSObject <IMUTLibSourceEvent>

- (instancetype)initWithViewControllerFullClassName:(NSString *)fullClassName
                                  useRepresentation:(IMUTLibUIViewControllerModuleClassNameRepresentation)representation;

- (NSString *)fullClassName;

- (NSString *)shortClassName;

@end
