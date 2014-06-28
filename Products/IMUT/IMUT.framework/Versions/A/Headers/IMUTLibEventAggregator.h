#import <Foundation/Foundation.h>
#import "IMUTLibDeltaEntity.h"
#import "IMUTLibSourceEvent.h"

// An event aggregator block is passed the new source event as first parameter and
// the last persisted source event as second parameter.
typedef IMUTLibDeltaEntity *(^event_aggregator_block_t)(id, id);

@interface IMUTLibEventAggregator : NSObject

+ (instancetype)sharedInstance;

- (void)enqueueSourceEvent:(NSObject <IMUTLibSourceEvent> *)sourceEvent;

- (void)registerAggregatorBlock:(event_aggregator_block_t)aggregatorBlock forEventsWithNames:(NSSet *)eventNames;

@end
