#import <Foundation/Foundation.h>
#import "IMUTLibDeltaEntity.h"
#import "IMUTLibEventAggregatorRegistry.h"

@protocol IMUTLibEventAggregator

// This method is invoked once by the IMUT runtime to let the receiver register its aggregator blocks
- (void)registerEventAggregatorBlocksInRegistry:(IMUTLibEventAggregatorRegistry *)registry;

@end
