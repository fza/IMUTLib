#import <UIKit/UIKit.h>

#import "IMUTLibOrientationModule.h"
#import "IMUTLibDeviceOrientationChangeEvent.h"
#import "IMUTLibOrientationModuleConstants.h"

static UIDeviceOrientation lastKnownDeviceOrientation;

@interface IMUTLibOrientationModule ()

- (void)deviceOrientationDidChange;

- (IMUTLibDeviceOrientationChangeEvent *)eventWithCurrentDeviceOrientationAndEnsureCreated:(BOOL)ensureCreated;

@end

@implementation IMUTLibOrientationModule

+ (void)initialize {
    // Initially assume portrait orientation
    lastKnownDeviceOrientation = UIDeviceOrientationPortrait;
}

#pragma mark IMUTLibModule class

+ (NSString *)moduleName {
    return kIMUTLibOrientationModule;
}

- (NSSet *)eventsWithInitialState {
    return $([self eventWithCurrentDeviceOrientationAndEnsureCreated:YES]);
}

- (void)startWithSession:(IMUTLibSession *)session {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];

    if (![UIDevice currentDevice].generatesDeviceOrientationNotifications) {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    }
}

- (void)stopWithSession:(IMUTLibSession *)session {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)registerEventAggregatorBlocksInRegistry:(IMUTLibEventAggregatorRegistry *)registry {
    IMUTLibEventAggregatorBlock aggregator = ^IMUTLibAggregatorOperation(IMUTLibDeviceOrientationChangeEvent *sourceEvent, IMUTLibDeviceOrientationChangeEvent *lastPersistedSourceEvent, IMUTLibPersistableEntity **deltaEntity) {
        if (!lastPersistedSourceEvent || [sourceEvent orientation] != [lastPersistedSourceEvent orientation]) {
            *deltaEntity = [IMUTLibPersistableEntity entityWithSourceEvent:sourceEvent];
            (*deltaEntity).entityType = IMUTLibPersistableEntityTypeStatus;

            return IMUTLibAggregationOperationEnqueue;
        }

        return IMUTLibAggregationOperationDequeue;
    };

    [registry registerEventAggregatorBlock:aggregator forEventName:kIMUTLibDeviceOrientationChangeEvent];
}

#pragma mark Private

- (void)deviceOrientationDidChange {
    id sourceEvent = [self eventWithCurrentDeviceOrientationAndEnsureCreated:NO];
    [[IMUTLibSourceEventCollection sharedInstance] addSourceEvent:sourceEvent];
}

- (IMUTLibDeviceOrientationChangeEvent *)eventWithCurrentDeviceOrientationAndEnsureCreated:(BOOL)ensureCreated {
    IMUTLibDeviceOrientationChangeEvent *sourceEvent = [[IMUTLibDeviceOrientationChangeEvent alloc] initWithCurrentOrientation];

    if (ensureCreated && !sourceEvent) {
        sourceEvent = [[IMUTLibDeviceOrientationChangeEvent alloc] initWithOrientation:lastKnownDeviceOrientation];
    } else if (sourceEvent) {
        lastKnownDeviceOrientation = [sourceEvent orientation];
    }

    return sourceEvent;
}

@end

CONSTRUCTOR {
    [IMUTLibMain registerModuleWithClass:[IMUTLibOrientationModule class]];
}
