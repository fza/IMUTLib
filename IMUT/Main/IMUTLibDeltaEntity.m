#import "IMUTLibDeltaEntity.h"
#import "Macros.h"

@interface IMUTLibDeltaEntity ()

@property(nonatomic, readwrite, retain) NSDictionary *parameters;
@property(nonatomic, readwrite, retain) id <IMUTLibSourceEvent> sourceEvent;

- (instancetype)initWithParameters:(NSDictionary *)parameters sourceEvent:(id <IMUTLibSourceEvent>)sourceEvent;

@end

@implementation IMUTLibDeltaEntity

@dynamic eventName;

DESIGNATED_INIT

+ (instancetype)deltaEntityWithParameters:(NSDictionary *)parameters sourceEvent:(id <IMUTLibSourceEvent>)sourceEvent {
    return [[self alloc] initWithParameters:parameters sourceEvent:sourceEvent];
}

+ (instancetype)deltaEntityWithSourceEvent:(id <IMUTLibSourceEvent>)sourceEvent {
    IMUTLibDeltaEntity *deltaEntity = [[self alloc] initWithParameters:nil sourceEvent:sourceEvent];
    deltaEntity.entityType = IMUTLibDeltaEntityTypeAbsolute;
    deltaEntity.shouldMergeWithSourceEventParams = YES;

    return deltaEntity;
}

- (NSString *)eventName {
    return self.sourceEvent.eventName;
}

- (NSDictionary *)parameters {
    NSDictionary *params = _parameters;

    if((params == nil || !params.count) && self.shouldMergeWithSourceEventParams) {
        return [self.sourceEvent parameters];
    } else if(self.shouldMergeWithSourceEventParams) {
        params = [[self.sourceEvent parameters] mutableCopy];
        [(NSMutableDictionary *) params addEntriesFromDictionary:_parameters];
    } else {
        params = @{};
    }

    return params;
}

#pragma mark Private

- (instancetype)initWithParameters:(NSDictionary *)parameters sourceEvent:(id <IMUTLibSourceEvent>)sourceEvent {
    if (self = [super init]) {
        self.parameters = parameters;
        self.sourceEvent = sourceEvent;
        self.entityType = IMUTLibDeltaEntityTypeDelta;
        self.shouldMergeWithSourceEventParams = NO;
    }

    return self;
}

@end
