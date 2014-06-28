#import <Foundation/Foundation.h>

@interface IMUTLibWeakWrappedObject : NSObject

+ (instancetype)wrapperForObject:(id)object;

- (id)wrappedObject;

@end
