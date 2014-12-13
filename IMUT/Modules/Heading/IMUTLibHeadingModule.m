#import "IMUTLibHeadingModule.h"
#import "IMUTLibHeadingChangeEvent.h"
#import "IMUTLibHeadingModuleConstants.h"
#import "IMUTLibConstants.h"

@interface IMUTLibHeadingModule ()

- (IMUTLibHeadingChangeEvent *)eventWithCurrentHeading;

- (void)initLocationManager;

@end

@implementation IMUTLibHeadingModule {
    CLLocationManager *_locationManager;
}

#pragma mark IMUTLibModule class

+ (NSString *)moduleName {
    return kIMUTLibHeadingModule;
}

- (instancetype)initWithConfig:(NSDictionary *)config {
    if (self = [super initWithConfig:config]) {
        [self performSelectorOnMainThread:@selector(initLocationManager)
                               withObject:nil
                            waitUntilDone:NO];
    }

    return self;
}

+ (NSDictionary *)defaultConfig {
    return @{
        kIMUTLibHeadingModuleConfigAllowDisplayCalibration : numNO,
        kIMUTLibHeadingModuleConfigMinDeltaHeadingDegrees : @5.0
    };
}

- (NSSet *)eventsWithInitialState {
    IMUTLibHeadingChangeEvent *sourceEvent = [self eventWithCurrentHeading];

    return sourceEvent ? $(sourceEvent) : nil;
}

- (void)startWithSession:(IMUTLibSession *)session {
    [_locationManager performSelectorOnMainThread:@selector(startUpdatingHeading)
                                       withObject:nil
                                    waitUntilDone:YES];
}

- (void)stopWithSession:(IMUTLibSession *)session {
    [_locationManager performSelectorOnMainThread:@selector(stopUpdatingHeading)
                                       withObject:nil
                                    waitUntilDone:YES];
}

- (void)registerEventAggregatorBlocksInRegistry:(IMUTLibEventAggregatorRegistry *)registry {
    IMUTLibEventAggregatorBlock aggregator = ^IMUTLibAggregatorOperation(IMUTLibHeadingChangeEvent *sourceEvent, IMUTLibHeadingChangeEvent *lastPersistedSourceEvent, IMUTLibPersistableEntity **deltaEntity) {
        if (!lastPersistedSourceEvent) {
            *deltaEntity = [IMUTLibPersistableEntity entityWithSourceEvent:sourceEvent];
            (*deltaEntity).entityType = IMUTLibPersistableEntityTypeAbsolute;

            return IMUTLibAggregationOperationEnqueue;
        } else {
            double newMagneticHeading = sourceEvent.heading.magneticHeading;
            double oldMagneticHeading = lastPersistedSourceEvent.heading.magneticHeading;
            double deltaMagneticHeading = oldMagneticHeading - newMagneticHeading;

            if (fabs(deltaMagneticHeading) > [_config[kIMUTLibHeadingModuleConfigMinDeltaHeadingDegrees] doubleValue]) {
                NSDictionary *deltaParams = @{
                    kIMUTLibHeadingChangeEventParamHeading : @(deltaMagneticHeading)
                };

                *deltaEntity = [IMUTLibPersistableEntity entityWithParameters:deltaParams
                                                                  sourceEvent:sourceEvent];

                return IMUTLibAggregationOperationEnqueue;
            }
        }

        return IMUTLibAggregationOperationDequeue;
    };

    [registry registerEventAggregatorBlock:aggregator forEventName:kIMUTLibHeadingChangeEvent];
}

#pragma mark CLLocationManagerDelegate protocol

- (void)initLocationManager {
    @synchronized (self) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.headingFilter = [_config[kIMUTLibHeadingModuleConfigMinDeltaHeadingDegrees] doubleValue];
        _locationManager.delegate = self;

        [_locationManager startUpdatingHeading];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    id sourceEvent = [[IMUTLibHeadingChangeEvent alloc] initWithHeading:newHeading];
    [[IMUTLibSourceEventCollection sharedInstance] addSourceEvent:sourceEvent];
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager {
    return [(NSNumber *) _config[kIMUTLibHeadingModuleConfigAllowDisplayCalibration] boolValue];
}

#pragma mark Private

- (IMUTLibHeadingChangeEvent *)eventWithCurrentHeading {
    CLHeading *heading = _locationManager.heading;

    if (heading) {
        return [[IMUTLibHeadingChangeEvent alloc] initWithHeading:heading];
    }

    return nil;
}

@end

CONSTRUCTOR {
    [IMUTLibMain registerModuleWithClass:[IMUTLibHeadingModule class]];
}
