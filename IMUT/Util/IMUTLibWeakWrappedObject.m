#import "IMUTLibWeakWrappedObject.h"

@interface IMUTLibWeakWrappedObject ()

- (instancetype)initWithObject:(id)obj;

@end

@implementation IMUTLibWeakWrappedObject {
    __weak id _wrappedObject;
}

+ (instancetype)wrapperForObject:(id)object {
    return [[self alloc] initWithObject:object];
}

- (instancetype)initWithObject:(id)object {
    if (self = [super init]) {
        _wrappedObject = object;
    }

    return self;
}

- (id)wrappedObject {
    return _wrappedObject;
}

@end
