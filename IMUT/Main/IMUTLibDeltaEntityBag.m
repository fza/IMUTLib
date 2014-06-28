#import "IMUTLibDeltaEntityBag.h"

@interface IMUTLibDeltaEntityBag ()

- (NSMutableDictionary *)backStore;

- (instancetype)initWithBackStore:(NSMutableDictionary *)store;

@end

@implementation IMUTLibDeltaEntityBag {
    NSMutableDictionary *_store;
}

@dynamic all;
@dynamic count;

- (instancetype)init {
    if (self = [super init]) {
        _store = [NSMutableDictionary dictionary];
    }

    return self;
}

- (NSArray *)all {
    return [_store allValues];
}

- (NSUInteger)count {
    return _store.count;
}

- (void)mergeWithCache:(IMUTLibDeltaEntityBag *)cache {
    [_store addEntriesFromDictionary:[cache backStore]];
}

- (void)addDeltaEntity:(IMUTLibDeltaEntity *)deltaEntity {
    if (deltaEntity) {
        _store[deltaEntity.eventName] = deltaEntity;
    }
}

- (void)removeDeltaEntityWithKey:(NSString *)key {
    if (key) {
        [_store removeObjectForKey:key];
    }
}

- (IMUTLibDeltaEntity *)deltaEntityForKey:(NSString *)key {
    return _store[key];
}

- (void)reset {
    _store = [NSMutableDictionary dictionary];
}

- (instancetype)copy {
    return [[[self class] alloc] initWithBackStore:[_store copy]];
}

#pragma mark Private

- (NSMutableDictionary *)backStore {
    return _store;
}

- (instancetype)initWithBackStore:(NSMutableDictionary *)store {
    if (self = [super init]) {
        _store = store;
    }

    return self;
}

@end
