#import "IMUTLibSourceEventQueue.h"
#import "IMUTLibFunctions.h"
#import "IMUTLibEventAggregatorRegistry.h"
#import "IMUTLibConstants.h"
#import "IMUTLibModule.h"
#import "IMUTLibEventSynchronizer.h"
#import "IMUTLibModuleRegistry.h"

@interface IMUTLibSourceEventQueue ()

- (void)synchronizerDidStart:(NSNotification *)notification;

@end

@implementation IMUTLibSourceEventQueue {
    dispatch_queue_t _dispatchQueue;
}

SINGLETON

- (instancetype)init {
    if (self = [super init]) {
        _dispatchQueue = makeDispatchQueue(@"source-event-queue", DISPATCH_QUEUE_SERIAL, DISPATCH_QUEUE_PRIORITY_HIGH);

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(synchronizerDidStart:)
                                                     name:IMUTLibEventSynchronizerDidStartNotification
                                                   object:nil];
    }

    return self;
}

- (void)enqueueSourceEvent:(id <IMUTLibSourceEvent>)sourceEvent {
    if (!sourceEvent) {
        return;
    }

    // This runs asynchronously to increase application performance
    dispatch_async(_dispatchQueue, ^{
        NSString *eventName = [sourceEvent eventName];
        IMUTLibEventSynchronizer *synchronizer = [IMUTLibEventSynchronizer sharedInstance];
        IMUTLibDeltaEntity *newDeltaEntity, *lastPersistedDeltaEntity = [synchronizer persistedEntityForKey:eventName];
        IMUTLibAggregatorOPReturn op = IMUTLibAggregationOperationNone;

        if (!lastPersistedDeltaEntity) {
            // There is no previous delta entity for this type of source event, no need to run the aggregator
            newDeltaEntity = [IMUTLibDeltaEntity deltaEntityWithSourceEvent:sourceEvent];
        } else {
            // Need to run the aggregator that should generate a delta entity for two source events
            IMUTLibEventAggregatorBlock aggregator = [[IMUTLibEventAggregatorRegistry sharedInstance] aggregatorBlockForEventName:eventName];
            NSAssert(aggregator, @"An aggregator block for events with name \"%@\" has not been registered.", eventName);

            op = aggregator(sourceEvent, [lastPersistedDeltaEntity sourceEvent], &newDeltaEntity);
        }

        switch (op) {
            case IMUTLibAggregationOperationNone:
                // Neither enqueue nor dequeue the delta entity
                break;

            case IMUTLibAggregationOperationEnqueue:
                NSAssert(newDeltaEntity, @"Aggregator wants to enqueue a delta entity that is unset for event name: \"%@\".", eventName);

                [synchronizer enqueueDeltaEntity:newDeltaEntity];
                break;

            case IMUTLibAggregationOperationDequeue:
                [synchronizer dequeueDeltaEntityWithKey:eventName];
        }
    });
}

#pragma mark Private

// Collect and enqueue initial events
- (void)synchronizerDidStart:(NSNotification *)notification {
    id <IMUTLibSourceEvent> sourceEvent;
    NSSet *sourceEvents;
    for (id <IMUTLibModule> moduleInstance in [[IMUTLibModuleRegistry sharedInstance] moduleInstancesWithType:IMUTLibModuleTypeEvented]) {
        if([(NSObject *) moduleInstance respondsToSelector:@selector(eventsWithCurrentState)]) {
            sourceEvents = [moduleInstance eventsWithCurrentState];
            if (sourceEvents) {
                for (sourceEvent in sourceEvents) {
                    [notification.object enqueueDeltaEntity:[IMUTLibDeltaEntity deltaEntityWithSourceEvent:sourceEvent]];
                }
            }
        }
    }
}

@end
