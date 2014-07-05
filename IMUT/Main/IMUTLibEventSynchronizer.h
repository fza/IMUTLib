#import <Foundation/Foundation.h>

#import "IMUTLibLogPacketStreamWriter.h"
#import "Macros.h"
#import "IMUTLibPersistableEntity.h"

// The synchronizer is the interface between the data capturing mechanism and
// the log writing. The aggregator(s) enqueue delta entities and the synchronizer
// persists them. The synchronizer is responsible for controlling the log writer,
// ensuring nothing is written before the clock starts ticking, e.g. the primary
// time source module started.
@interface IMUTLibEventSynchronizer : NSObject <IMUTLibStreamLogWriterDelegate>

@property(nonatomic, readonly, assign) NSTimeInterval lastPersistedEntityTime;

@property(nonatomic, readwrite, assign) NSTimeInterval syncTimeInterval;

@property(nonatomic, readonly, retain) IMUTLibLogPacketStreamWriter *logWriter;

@property(nonatomic, readonly, retain) dispatch_queue_t dispatchQueue;

@property(nonatomic, readonly) unsigned long eventCount;

SINGLETON_INTERFACE

// Return the entity last persisted for a given key
- (IMUTLibPersistableEntity *)persistedEntityForKey:(NSString *)key;

// The aggregator(s) place newly created entities using this method
- (void)enqueueEntity:(IMUTLibPersistableEntity *)entity;

// If an aggregator decides that the source event of the last persisted
// entity equals the most recent one, it must dequeue the currently
// queued delta entity, so that the synchronizer won't persist it again.
- (void)dequeueEntityWithKey:(NSString *)key;

// Clears the cache
- (void)clearCache;

// Aligns a time interval with the sync time interval
- (NSTimeInterval)alignTimeInterval:(NSTimeInterval)timeInterval;

@end
