#import "IMUTLibHeadingModule.h"
#import "IMUTLibConstants.h"
#import "IMUTLibHeadingModuleConstants.h"
#import "IMUTLibHeadingChangeEvent.h"
#import "IMUTLibSourceEventQueue.h"
#import "IMUTLibMain.h"

@interface IMUTLibHeadingModule ()

- (IMUTLibHeadingChangeEvent *)eventWithCurrentHeading;

- (void)initLocationManager;

@end

@implementation IMUTLibHeadingModule {
    CLLocationManager *_locationManager;
    BOOL _active;
}

#pragma mark IMUTLibModule protocol

+ (NSString *)moduleName {
    return kIMUTLibHeadingModule;
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
        kIMUTLibHeadingModuleConfigAllowDisplayCalibration : cNO,
        kIMUTLibHeadingModuleConfigMinDeltaHeadingDegrees : @5.0
    };
}

- (NSSet *)eventsWithCurrentState {
    IMUTLibHeadingChangeEvent *eventWithCurrentHeading = [self eventWithCurrentHeading];

    if (eventWithCurrentHeading) {
        return $(
            eventWithCurrentHeading
        );
    }

    return nil;
}

- (void)start {
    @synchronized (self) {
        _active = YES;
        [_locationManager startUpdatingHeading];
    }
}

- (void)pause {
    @synchronized (self) {
        _active = NO;
        [_locationManager stopUpdatingHeading];
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
    IMUTLibEventAggregatorBlock aggregator = ^IMUTLibAggregatorOPReturn(IMUTLibHeadingChangeEvent *sourceEvent, IMUTLibHeadingChangeEvent *lastPersistedSourceEvent, IMUTLibDeltaEntity **deltaEntity) {
        double newMagneticHeading = sourceEvent.heading.magneticHeading;
        double oldMagneticHeading = lastPersistedSourceEvent.heading.magneticHeading;
        double deltaMagneticHeading = oldMagneticHeading - newMagneticHeading;

        if (fabs(deltaMagneticHeading) > [_config[kIMUTLibHeadingModuleConfigMinDeltaHeadingDegrees] doubleValue]) {
            NSDictionary *deltaParams = @{
                kIMUTLibHeadingChangeEventParamHeading : [NSNumber numberWithDouble:deltaMagneticHeading]
            };

            *deltaEntity = [IMUTLibDeltaEntity deltaEntityWithParameters:deltaParams
                                                             sourceEvent:sourceEvent];

            return IMUTLibAggregationOperationEnqueue;
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

        if (_active) {
            [self start];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    id sourceEvent = [[IMUTLibHeadingChangeEvent alloc] initWithHeading:newHeading];
    [[IMUTLibSourceEventQueue sharedInstance] enqueueSourceEvent:sourceEvent];
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
