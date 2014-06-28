#import "IMUTLibLocationModule.h"
#import "IMUTLibConstants.h"
#import "IMUTLibLocationModuleConstants.h"
#import "IMUTLibLocationChangeEvent.h"
#import "IMUTLibSourceEventQueue.h"
#import "IMUTLibMain.h"

@interface IMUTLibLocationModule ()

- (IMUTLibLocationChangeEvent *)eventWithCurrentLocation;

- (void)initLocationManager;

@end

@implementation IMUTLibLocationModule {
    CLLocationManager *_locationManager;
    BOOL _active;
}

#pragma mark IMUTLibModule protocol

+ (NSString *)moduleName {
    return kIMUTLibLocationModule;
}

- (instancetype)initWithConfig:(NSDictionary *)config {
    if (self = [super initWithConfig:config]) {
        _active = NO;

        [self performSelectorOnMainThread:@selector(initLocationManager) withObject:nil waitUntilDone:NO];
    }

    return self;
}

+ (NSDictionary *)defaultConfig {
    return @{
        kIMUTLibLocationModuleConfigOnlyIfAlreadyAuthorized : cNO,
        kIMUTLibLocationModuleConfigMinDistanceMeters : @5.0
    };
}

- (NSSet *)eventsWithCurrentState {
    IMUTLibLocationChangeEvent *eventWithCurrentLocation = [self eventWithCurrentLocation];

    if (eventWithCurrentLocation) {
        return $(
            eventWithCurrentLocation
        );
    }

    return nil;
}

- (void)start {
    @synchronized (self) {
        _active = YES;
        [_locationManager startUpdatingLocation];
    }
}

- (void)pause {
    @synchronized (self) {
        _active = NO;
        [_locationManager stopUpdatingLocation];
    }
}

- (void)resume {
    [self start];
}

- (void)terminate {
    [self pause];
}

#pragma mark IMUTLibModuleEventedProducer protocol

- (void)registerEventAggregatorBlocksInRegistry:(IMUTLibEventAggregatorRegistry *)registry {
    IMUTLibEventAggregatorBlock aggregator = ^IMUTLibAggregatorOPReturn(IMUTLibLocationChangeEvent *sourceEvent, IMUTLibLocationChangeEvent *lastPersistedSourceEvent, IMUTLibDeltaEntity **deltaEntity) {
        CLLocation *newLocation = sourceEvent.location;
        CLLocation *oldLocation = lastPersistedSourceEvent.location;
        double distance = [newLocation distanceFromLocation:oldLocation];

        if (distance >= [_config[kIMUTLibLocationModuleConfigMinDistanceMeters] doubleValue]) {
            NSDictionary *deltaParams = @{
                kIMUTLibLocationChangeEventParamDistance : [NSNumber numberWithDouble:(round(distance * 100.0) / 100.0)]
            };

            *deltaEntity = [IMUTLibDeltaEntity deltaEntityWithParameters:deltaParams
                                                             sourceEvent:sourceEvent];
            (*deltaEntity).shouldMergeWithSourceEventParams = YES;

            return IMUTLibAggregationOperationEnqueue;
        }

        return IMUTLibAggregationOperationDequeue;
    };

    [registry registerEventAggregatorBlock:aggregator forEventName:kIMUTLibLocationChangeEvent];
}

#pragma mark CLLocationManagerDelegate protocol

- (void)initLocationManager {
    @synchronized (self) {
        if ([_config[kIMUTLibLocationModuleConfigOnlyIfAlreadyAuthorized] boolValue] && [CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized) {
            // Will never instanciate the CLLocationManager
            return;
        }

        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.distanceFilter = [_config[kIMUTLibLocationModuleConfigMinDistanceMeters] doubleValue];

        if (_active) {
            [self start];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    id sourceEvent = [[IMUTLibLocationChangeEvent alloc] initWithLocation:[locations lastObject]];
    [[IMUTLibSourceEventQueue sharedInstance] enqueueSourceEvent:sourceEvent];
}

#pragma mark Private

- (IMUTLibLocationChangeEvent *)eventWithCurrentLocation {
    CLLocation *currentLocation = _locationManager.location;

    if (currentLocation) {
        return [[IMUTLibLocationChangeEvent alloc] initWithLocation:currentLocation];
    }

    return nil;
}

@end

CONSTRUCTOR {
    [IMUTLibMain registerModuleWithClass:[IMUTLibLocationModule class]];
}
