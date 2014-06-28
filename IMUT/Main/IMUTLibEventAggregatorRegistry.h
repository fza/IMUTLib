#import <Foundation/Foundation.h>
#import "IMUTLibDeltaEntity.h"
#import "IMUTLibSourceEvent.h"
#import "Macros.h"

typedef NS_ENUM(NSUInteger, IMUTLibAggregatorOPReturn) {
    IMUTLibAggregationOperationNone = 0,    // Tells the collector that it should neither enqueue nor dequeue anything
    IMUTLibAggregationOperationEnqueue = 1, // Tells the collector to enqueue a new delta entity
    IMUTLibAggregationOperationDequeue = 2  // Tells the collector to dequeue a delta entity, because the last persisted one is still valid
};

// An event aggregator block
typedef IMUTLibAggregatorOPReturn(^IMUTLibEventAggregatorBlock)(id sourceEvent, id lastPersistedSourceEvent, IMUTLibDeltaEntity **deltaEntity);

@interface IMUTLibEventAggregatorRegistry : NSObject

+ (instancetype)sharedInstance;

- (IMUTLibEventAggregatorBlock)aggregatorBlockForEventName:(NSString *)eventName;

- (void)registerEventAggregatorBlock:(IMUTLibEventAggregatorBlock)block
                  forEventsWithNames:(NSSet *)eventNames;

- (void)registerEventAggregatorBlock:(IMUTLibEventAggregatorBlock)block
                        forEventName:(NSString *)eventName;

@end
