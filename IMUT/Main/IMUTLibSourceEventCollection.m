#import "IMUTLibSourceEventCollection.h"
#import "IMUTLibEventAggregatorRegistry.h"
#import "IMUTLibEventSynchronizer.h"
#import "IMUTLibConstants.h"
#import "IMUTLibModule.h"
#import "IMUTLibModuleRegistry.h"
#import "IMUTLibFunctions.h"

// This is probably too high (using this value for the purpose of testing)
#define MAX_SECS_TO_WAIT_FOR_INITIAL_EVENTS 5.0
#define MAX_SECS_TO_WAIT_FOR_FINAL_EVENTS 20.0

@interface IMUTLibSourceEventCollection ()

- (IMUTLibAggregatorOperation)aggregateSourceEvent:(NSObject <IMUTLibSourceEvent> *)sourceEvent forEntity:(IMUTLibPersistableEntity **)entity;

- (void)synchronizerDidStart;

- (void)synchronizerWillStop;

@end

@implementation IMUTLibSourceEventCollection {
    IMUTLibEventSynchronizer *_synchronizer;
    dispatch_queue_t _dispatchQueue;
}

SINGLETON

- (instancetype)init {
    if (self = [super init]) {
        _synchronizer = [IMUTLibEventSynchronizer sharedInstance];
        _dispatchQueue = makeDispatchQueue(@"event-collector", DISPATCH_QUEUE_SERIAL, DISPATCH_QUEUE_PRIORITY_LOW);

        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];

        [defaultCenter addObserver:self
                          selector:@selector(synchronizerDidStart)
                              name:IMUTLibEventSynchronizerDidStartNotification
                            object:nil];

        [defaultCenter addObserver:self
                          selector:@selector(synchronizerWillStop)
                              name:IMUTLibEventSynchronizerWillStopNotification
                            object:nil];
    }

    return self;
}

- (void)addSourceEvent:(NSObject <IMUTLibSourceEvent> *)sourceEvent now:(BOOL)now {
    if (!sourceEvent) {
        return;
    }

    void (^addSourceEvent)(void) = ^{
        IMUTLibPersistableEntity *entity;
        IMUTLibAggregatorOperation operation = [self aggregateSourceEvent:sourceEvent forEntity:&entity];
        [self processEntity:entity withOperation:operation];
    };

    if (now) {
        dispatch_sync(_dispatchQueue, addSourceEvent);
    } else {
        dispatch_async(_dispatchQueue, addSourceEvent);
    }
}

- (void)addSourceEvent:(NSObject <IMUTLibSourceEvent> *)sourceEvent {
    [self addSourceEvent:sourceEvent now:NO];
}

#pragma mark Private

- (IMUTLibAggregatorOperation)aggregateSourceEvent:(NSObject <IMUTLibSourceEvent> *)sourceEvent forEntity:(IMUTLibPersistableEntity **)entity {
    NSString *eventName = [sourceEvent eventName];
    IMUTLibPersistableEntity *lastPersistedDeltaEntity = [_synchronizer persistedEntityForKey:eventName];
    NSObject <IMUTLibSourceEvent> *lastPersistedSourceEvent = lastPersistedDeltaEntity ? [lastPersistedDeltaEntity sourceEvent] : nil;

    IMUTLibEventAggregatorBlock aggregator = [[IMUTLibEventAggregatorRegistry sharedInstance] aggregatorBlockForEventName:eventName];
    NSAssert(aggregator, @"An aggregator block for events with name \"%@\" has not been registered.", eventName);

    // Passes the address of the delta entity where the aggregator should directly save it
    IMUTLibAggregatorOperation operation = aggregator(sourceEvent, lastPersistedSourceEvent, entity);

    return operation;
}

- (void)processEntity:(IMUTLibPersistableEntity *)entity withOperation:(IMUTLibAggregatorOperation)operation {
    switch (operation) {
        case IMUTLibAggregationOperationNone:
            // Neither enqueue nor dequeue the delta entity
            break;

        case IMUTLibAggregationOperationEnqueue:
            NSAssert(entity, @"Aggregator wants to enqueue a delta entity that is unset for event name: \"%@\".", [entity.sourceEvent eventName]);

            [_synchronizer enqueueEntity:entity];
            break;

        case IMUTLibAggregationOperationDequeue:
            [_synchronizer dequeueEntityWithKey:[entity.sourceEvent eventName]];
    }
}

// Collect and enqueue initial events when the synchronizer starts
// The synchronizer will mark them "initial" automatically
- (void)synchronizerDidStart {
    [self askModulesForSourceEventsWithSelector:@selector(eventsWithInitialState)];
}

// Collect and enqueue initial events when the synchronizer stops
// The synchronizer will mark them "final" automatically
- (void)synchronizerWillStop {
    [self askModulesForSourceEventsWithSelector:@selector(eventsWithFinalState)];
}

- (void)askModulesForSourceEventsWithSelector:(SEL)selector {
    dispatch_queue_t dispatchQueue = makeDispatchQueue(@"event-collector-batch", DISPATCH_QUEUE_CONCURRENT, DISPATCH_QUEUE_PRIORITY_LOW);
    dispatch_group_t dispatchGroup = dispatch_group_create();
    __block BOOL didEnqueueEntities = NO;
    for (IMUTLibModule *moduleInstance in [[IMUTLibModuleRegistry sharedInstance] moduleInstancesWithType:IMUTLibModuleTypeEvented]) {
        dispatch_group_async(dispatchGroup, dispatchQueue, ^{
            NSObject <IMUTLibSourceEvent> *sourceEvent;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            NSSet *sourceEvents = [moduleInstance performSelector:selector];
#pragma clang diagnostic pop

            if (sourceEvents) {
                for (sourceEvent in sourceEvents) {
                    didEnqueueEntities = YES;
                    [_synchronizer enqueueEntity:[IMUTLibPersistableEntity entityWithSourceEvent:sourceEvent]];
                }
            }
        });
    }

    if (didEnqueueEntities) {
        dispatch_group_enter(dispatchGroup);
        dispatch_async(_dispatchQueue, ^{
            dispatch_group_leave(dispatchGroup);
        });
    }

    dispatch_group_wait(dispatchGroup, dispatch_time(DISPATCH_TIME_NOW, (int64_t) MAX_SECS_TO_WAIT_FOR_FINAL_EVENTS * NSEC_PER_SEC));
}

@end
