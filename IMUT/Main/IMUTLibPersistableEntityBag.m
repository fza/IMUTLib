#import "IMUTLibPersistableEntityBag.h"

@interface IMUTLibPersistableEntityBag ()

- (NSMutableDictionary *)backStore;

- (instancetype)initWithBackStore:(NSMutableDictionary *)store;

@end

@implementation IMUTLibPersistableEntityBag {
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
    // TODO: Check this
    return [_store allValues];
}

- (NSUInteger)count {
    return _store.count;
}

- (void)mergeWithBag:(IMUTLibPersistableEntityBag *)bag {
    [_store addEntriesFromDictionary:[bag backStore]];
}

- (void)addDeltaEntity:(IMUTLibPersistableEntity *)deltaEntity {
    if (deltaEntity) {
        _store[deltaEntity.eventName] = deltaEntity;
    }
}

- (void)removeDeltaEntityWithKey:(NSString *)key {
    if (key) {
        [_store removeObjectForKey:key];
    }
}

- (IMUTLibPersistableEntity *)entityForKey:(NSString *)key {
    return _store[key];
}

- (void)reset {
    _store = [NSMutableDictionary dictionary];
}

- (instancetype)copy {
    return [[[self class] alloc] initWithBackStore:_store];
}

#pragma mark Private

- (NSMutableDictionary *)backStore {
    return _store;
}

- (instancetype)initWithBackStore:(NSDictionary *)store {
    if (self = [super init]) {
        _store = [NSMutableDictionary dictionaryWithDictionary:store];
    }

    return self;
}

@end
