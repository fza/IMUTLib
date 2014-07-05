#import "IMUTLibPersistableEntity.h"
#import "Macros.h"
#import "IMUTLibConstants.h"

@interface IMUTLibPersistableEntity ()

@property(nonatomic, readwrite, retain) NSDictionary *parameters;
@property(nonatomic, readwrite, retain) NSObject <IMUTLibSourceEvent> *sourceEvent;

- (instancetype)initWithParameters:(NSDictionary *)parameters sourceEvent:(NSObject <IMUTLibSourceEvent> *)sourceEvent;

@end

@implementation IMUTLibPersistableEntity

@dynamic eventName;

DESIGNATED_INIT

+ (instancetype)entityWithParameters:(NSDictionary *)parameters sourceEvent:(NSObject <IMUTLibSourceEvent> *)sourceEvent {
    return [[self alloc] initWithParameters:parameters sourceEvent:sourceEvent];
}

+ (instancetype)entityWithSourceEvent:(NSObject <IMUTLibSourceEvent> *)sourceEvent {
    IMUTLibPersistableEntity *entity = [[self alloc] initWithParameters:nil sourceEvent:sourceEvent];
    entity.entityType = IMUTLibPersistableEntityTypeAbsolute;
    entity.shouldMergeWithSourceEventParams = YES;

    return entity;
}

- (NSString *)eventName {
    return self.sourceEvent.eventName;
}

- (NSDictionary *)parameters {
    if (!_parameters || !_parameters.count) {
        if (_shouldMergeWithSourceEventParams) {
            return [_sourceEvent parameters];
        }

        return nil;
    } else if (_shouldMergeWithSourceEventParams) {
        NSMutableDictionary *params = [[_sourceEvent parameters] mutableCopy];
        [params addEntriesFromDictionary:_parameters];
    }

    return _parameters;
}

#pragma mark Private

- (instancetype)initWithParameters:(NSDictionary *)parameters sourceEvent:(NSObject <IMUTLibSourceEvent> *)sourceEvent {
    if (self = [super init]) {
        _parameters = parameters;
        _sourceEvent = sourceEvent;
        _entityType = IMUTLibPersistableEntityTypeDelta;
        _shouldMergeWithSourceEventParams = NO;
    }

    return self;
}

@end
