#import <Foundation/Foundation.h>
#import "IMUTLibSession.h"
#import "IMUTLibDeltaEntityCache.h"
#import "IMUTLibLogPacketStreamWriter.h"
#import "Macros.h"

// The synchronizer is the interface between the data capturing mechanism and
// the log writing. The aggregator(s) enqueue delta entities and the synchronizer
// persists them. The synchronizer is responsible for controlling the log writer,
// ensuring nothing is written before the clock starts ticking, e.g. the primary
// time source module started.
@interface IMUTLibEventSynchronizer : NSObject <IMUTLibStreamLogWriterDelegate>

@property(nonatomic, readwrite, assign) NSTimeInterval syncTimeInterval;

SINGLETON_INTERFACE

// Return the entity last persisted for a given key
- (IMUTLibDeltaEntity *)persistedEntityForKey:(NSString *)key;

// The aggregator(s) place newly created delta entities using this method
- (void)enqueueDeltaEntity:(id)deltaEntity;

// If an aggregator decides that the source event of the last persisted
// entity equals the most recent one, it must dequeue the currently
// queued delta entity, so that the synchronizer won't persist it again.
- (void)dequeueDeltaEntityWithKey:(NSString *)key;

@end
