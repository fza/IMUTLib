#import "IMUTLibDeltaEntityCache.h"

@interface IMUTLibDeltaEntityCache ()

- (NSMutableDictionary *)backStore;

@end

@implementation IMUTLibDeltaEntityCache {
    NSMutableDictionary *_store;
}

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

- (void)mergeWithCache:(IMUTLibDeltaEntityCache *)cache {
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

#pragma mark Private

- (NSMutableDictionary *)backStore {
    return _store;
}

@end
