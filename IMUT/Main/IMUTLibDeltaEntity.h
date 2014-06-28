#import <Foundation/Foundation.h>
#import "IMUTLibSourceEvent.h"

typedef NS_ENUM(NSUInteger, IMUTLibDeltaEntityType) {
    IMUTLibDeltaEntityTypeAbsolute = 1,
    IMUTLibDeltaEntityTypeDelta = 2,
    IMUTLibDeltaEntityTypeStatus = 3,
    IMUTLibDeltaEntityTypeMixed = 4,
    IMUTLibDeltaEntityTypeOther = 5
};

@interface IMUTLibDeltaEntity : NSObject

// Name extracted from backing source event
@property(nonatomic, readonly, retain) NSString *eventName;

// Parameters to persist
@property(nonatomic, readonly, retain) NSDictionary *parameters;

// The backing source event
@property(nonatomic, readonly, retain) id <IMUTLibSourceEvent> sourceEvent;

// The delta entity type, defaults to `IMUTLibDeltaEntityTypeDelta`
@property(nonatomic, readwrite, assign) IMUTLibDeltaEntityType entityType;

// Set to YES if the delta entity should merge its params with the backing source event's
// params upon persist.
@property(nonatomic, readwrite, assign) BOOL shouldMergeWithSourceEventParams;

// Initializer to use if the delta entity's parameters differ from the source event, i.e.
// the aggregator calculated delta values.
// `entityType` defaults to `IMUTLibDeltaEntityTypeDelta`
+ (instancetype)deltaEntityWithParameters:(NSDictionary *)parameters
                              sourceEvent:(id <IMUTLibSourceEvent>)sourceEvent;

// Initializer to use if the delta entity only stores absolute values, which do not differ
// from those that can be derived from the backing source event.
// `entityType` defaults to `IMUTLibDeltaEntityTypeAbsolute`
+ (instancetype)deltaEntityWithSourceEvent:(id <IMUTLibSourceEvent>)sourceEvent;

@end
