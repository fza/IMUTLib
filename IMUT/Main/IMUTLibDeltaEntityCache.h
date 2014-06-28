#import <Foundation/Foundation.h>
#import "IMUTLibDeltaEntity.h"

// The cache for all delta entities to be persisted every synchronization interval.
// Not thread safe, because the synchronizer handles the thread safety anyway, thus
// making this class thread safe would add additional complexity.
@interface IMUTLibDeltaEntityCache : NSObject

@property(nonatomic, readonly, retain) NSArray *all;
@property(nonatomic, readonly, assign) NSUInteger count;

- (void)mergeWithCache:(IMUTLibDeltaEntityCache *)cache;

- (void)addDeltaEntity:(IMUTLibDeltaEntity *)deltaEntity;

- (void)removeDeltaEntityWithKey:(NSString *)key;

- (IMUTLibDeltaEntity *)deltaEntityForKey:(NSString *)key;

@end
