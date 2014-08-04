#import <Foundation/Foundation.h>

@interface IMUTLibWrappedUIObject : NSObject

@property (nonatomic, readonly, weak) id wrappedObject;

+ (instancetype)wrapperWithObject:(id)object;

@end
