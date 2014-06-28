#import <Foundation/Foundation.h>
#import "IMUTLibEventAggregator.h"

@protocol IMUTLibEventProducer

- (event_aggregator_block_t)eventAggregatorBlock;

@end
