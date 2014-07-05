#import <Foundation/Foundation.h>

#import "IMUTLibPersistableEntity.h"
#import "Macros.h"

// Types of operations an aggregator can request from the synchronizer.
typedef NS_ENUM(NSUInteger, IMUTLibAggregatorOperation) {
    IMUTLibAggregationOperationNone = 0,    // Tells the collector that it should neither enqueue nor dequeue anything
    IMUTLibAggregationOperationEnqueue = 1, // Tells the collector to enqueue a new delta entity
    IMUTLibAggregationOperationDequeue = 2  // Tells the collector to dequeue a delta entity, because the last persisted one is still valid
};

// The event aggregator block type
typedef IMUTLibAggregatorOperation(^IMUTLibEventAggregatorBlock)(id sourceEvent, id lastPersistedSourceEvent, IMUTLibPersistableEntity **deltaEntity);

@interface IMUTLibEventAggregatorRegistry : NSObject

+ (instancetype)sharedInstance; // SINGLETON_INTERFACE

- (IMUTLibEventAggregatorBlock)aggregatorBlockForEventName:(NSString *)eventName;

- (void)registerEventAggregatorBlock:(IMUTLibEventAggregatorBlock)block
                  forEventsWithNames:(NSSet *)eventNames;

- (void)registerEventAggregatorBlock:(IMUTLibEventAggregatorBlock)block
                        forEventName:(NSString *)eventName;

@end
