#import "IMUTLibWrappedUIObject.h"

@interface IMUTLibWrappedUIObject ()

@property(nonatomic, readwrite, weak) id wrappedObject;

- (instancetype)initWithObject:(id)object;

@end

@implementation IMUTLibWrappedUIObject

+ (instancetype)wrapperWithObject:(id)object {
    return [[self alloc] initWithObject:object];
}

#pragma mark Private

- (instancetype)initWithObject:(id)object {
    if(self = [super init]) {
        self.wrappedObject = object;
    }

    return self;
}

@end
