#import <Foundation/Foundation.h>

#import "IMUTLibPersistableEntity.h"

// The cache for all delta entities to be persisted every synchronization interval.
// Not thread safe, because the synchronizer handles the thread safety anyway, thus
// making this class thread safe would add additional complexity.
@interface IMUTLibPersistableEntityBag : NSObject

@property(nonatomic, readonly, retain) NSArray *all;
@property(nonatomic, readonly, assign) NSUInteger count;

- (void)mergeWithBag:(IMUTLibPersistableEntityBag *)bag;

- (void)addDeltaEntity:(IMUTLibPersistableEntity *)deltaEntity;

- (void)removeDeltaEntityWithKey:(NSString *)key;

- (IMUTLibPersistableEntity *)entityForKey:(NSString *)key;

- (void)reset;

- (instancetype)copy;

@end
