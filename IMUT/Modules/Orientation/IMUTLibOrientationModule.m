#import "Macros.h"
#import <UIKit/UIKit.h>
#import "IMUTLibOrientationModule.h"
#import "IMUTLibDeviceOrientationChangeEvent.h"
#import "IMUTLibSourceEventQueue.h"
#import "IMUTLibMain.h"
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

#pragma mark IMUTLibModule protocol

+ (NSString *)moduleName {
    return kIMUTLibOrientationModule;
}

- (NSSet *)eventsWithCurrentState {
    return $(
        [self eventWithCurrentDeviceOrientationAndEnsureCreated:YES]
    );
}

- (void)start {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];

    if (![UIDevice currentDevice].generatesDeviceOrientationNotifications) {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    }
}

- (void)pause {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)resume {
    [self start];
}

- (void)terminate {
    [self pause];
}

#pragma mark IMUTLibModuleEventedProducer protocol

- (void)registerEventAggregatorBlocksInRegistry:(IMUTLibEventAggregatorRegistry *)registry {
    IMUTLibEventAggregatorBlock aggregator = ^IMUTLibAggregatorOPReturn(IMUTLibDeviceOrientationChangeEvent *sourceEvent, IMUTLibDeviceOrientationChangeEvent *lastPersistedSourceEvent, IMUTLibDeltaEntity **deltaEntity) {
        if ([sourceEvent orientation] != [lastPersistedSourceEvent orientation]) {
            *deltaEntity = [IMUTLibDeltaEntity deltaEntityWithSourceEvent:sourceEvent];
            (*deltaEntity).entityType = IMUTLibDeltaEntityTypeStatus;

            return IMUTLibAggregationOperationEnqueue;
        }

        return IMUTLibAggregationOperationDequeue;
    };

    [registry registerEventAggregatorBlock:aggregator forEventName:kIMUTLibDeviceOrientationChangeEvent];
}

#pragma mark Private

- (void)deviceOrientationDidChange {
    id sourceEvent = [self eventWithCurrentDeviceOrientationAndEnsureCreated:NO];
    [[IMUTLibSourceEventQueue sharedInstance] enqueueSourceEvent:sourceEvent];
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
