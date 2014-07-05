#import "IMUTLibLocationModule.h"
#import "IMUTLibLocationChangeEvent.h"
#import "IMUTLibLocationModuleConstants.h"
#import "IMUTLibConstants.h"

@interface IMUTLibLocationModule ()

- (IMUTLibLocationChangeEvent *)eventWithCurrentLocation;

- (void)initLocationManager;

@end

@implementation IMUTLibLocationModule {
    CLLocationManager *_locationManager;
}

#pragma mark IMUTLibModule class

+ (NSString *)moduleName {
    return kIMUTLibLocationModule;
}

- (instancetype)initWithConfig:(NSDictionary *)config {
    if (self = [super initWithConfig:config]) {
        [self performSelectorOnMainThread:@selector(initLocationManager) withObject:nil waitUntilDone:NO];
    }

    return self;
}

+ (NSDictionary *)defaultConfig {
    return @{
        kIMUTLibLocationModuleConfigOnlyIfAlreadyAuthorized : numNO,
        kIMUTLibLocationModuleConfigMinDistanceMeters : @5.0
    };
}

- (NSSet *)eventsWithInitialState {
    IMUTLibLocationChangeEvent *sourceEvent = [self eventWithCurrentLocation];

    return sourceEvent ? $(sourceEvent) : nil;
}

- (void)startWithSession:(IMUTLibSession *)session {
    [_locationManager performSelectorOnMainThread:@selector(startUpdatingLocation)
                                       withObject:nil
                                    waitUntilDone:YES];
}

- (void)stopWithSession:(IMUTLibSession *)session {
    [_locationManager performSelectorOnMainThread:@selector(stopUpdatingLocation)
                                       withObject:nil
                                    waitUntilDone:YES];
}

- (void)registerEventAggregatorBlocksInRegistry:(IMUTLibEventAggregatorRegistry *)registry {
    IMUTLibEventAggregatorBlock aggregator = ^IMUTLibAggregatorOperation(IMUTLibLocationChangeEvent *sourceEvent, IMUTLibLocationChangeEvent *lastPersistedSourceEvent, IMUTLibPersistableEntity **deltaEntity) {
        if (!lastPersistedSourceEvent) {
            *deltaEntity = [IMUTLibPersistableEntity entityWithSourceEvent:sourceEvent];
            (*deltaEntity).entityType = IMUTLibPersistableEntityTypeAbsolute;

            return IMUTLibAggregationOperationEnqueue;
        } else {
            CLLocation *newLocation = sourceEvent.location;
            CLLocation *oldLocation = lastPersistedSourceEvent.location;
            double distance = [newLocation distanceFromLocation:oldLocation];

            if (distance >= [_config[kIMUTLibLocationModuleConfigMinDistanceMeters] doubleValue]) {
                NSDictionary *deltaParams = @{
                    kIMUTLibLocationChangeEventParamDistance : [NSNumber numberWithDouble:(round(distance * 100.0) / 100.0)]
                };

                *deltaEntity = [IMUTLibPersistableEntity entityWithParameters:deltaParams sourceEvent:sourceEvent];
                (*deltaEntity).shouldMergeWithSourceEventParams = YES;

                return IMUTLibAggregationOperationEnqueue;
            }
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

        [_locationManager startUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    id sourceEvent = [[IMUTLibLocationChangeEvent alloc] initWithLocation:[locations lastObject]];
    [[IMUTLibSourceEventCollection sharedInstance] addSourceEvent:sourceEvent];
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
