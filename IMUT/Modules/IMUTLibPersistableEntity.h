#import <Foundation/Foundation.h>

#import "IMUTLibSourceEvent.h"

typedef NS_ENUM(NSUInteger, IMUTLibPersistableEntityType) {
    IMUTLibPersistableEntityTypeAbsolute = 1,
    IMUTLibPersistableEntityTypeDelta = 2,
    IMUTLibPersistableEntityTypeStatus = 3,
    IMUTLibPersistableEntityTypeMixed = 4,
    IMUTLibPersistableEntityTypeOther = 5
};

typedef NS_ENUM(NSUInteger, IMUTLibPersistableEntityMarking) {
    IMUTLibPersistableEntityMarkInitial = 1,
    IMUTLibPersistableEntityMarkFinal = 2
};

@interface IMUTLibPersistableEntity : NSObject

// Name extracted from backing source event
@property(nonatomic, readonly, retain) NSString *eventName;

// Parameters to persist
@property(nonatomic, readonly, retain) NSDictionary *parameters;

// The backing source event
@property(nonatomic, readonly, retain) NSObject <IMUTLibSourceEvent> *sourceEvent;

// The delta entity type, defaults to `IMUTLibPersistableEntityTypeDelta`
@property(nonatomic, readwrite, assign) IMUTLibPersistableEntityType entityType;

// Set to YES if the delta entity should merge its params with the backing source event's
// params upon persist.
@property(nonatomic, readwrite, assign) BOOL shouldMergeWithSourceEventParams;

// Optionally mark this entity
@property(nonatomic, readwrite, assign) IMUTLibPersistableEntityMarking entityMarking;

// Initializer to use if the delta entity's parameters differ from the source event, i.e.
// the aggregator calculated delta values.
// `entityType` defaults to `IMUTLibPersistableEntityTypeDelta`
+ (instancetype)entityWithParameters:(NSDictionary *)parameters
                         sourceEvent:(NSObject <IMUTLibSourceEvent> *)sourceEvent;

// Initializer to use if the delta entity only stores absolute values, which do not differ
// from those that can be derived from the backing source event.
// `entityType` defaults to `IMUTLibPersistableEntityTypeAbsolute`
+ (instancetype)entityWithSourceEvent:(NSObject <IMUTLibSourceEvent> *)sourceEvent;

@end
