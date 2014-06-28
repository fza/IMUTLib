#import "IMUTLibDefaultTimeSource.h"
#import "IMUTLibConstants.h"
#import "IMUTLibUtil.h"
#import "IMUTLibFunctions.h"

NSUInteger IMUTLibDefaultTimeSourcePreference = 0;

@interface IMUTLibDefaultTimeSource ()

- (void)didReceiveStartResumeNotification:(NSNotification *)notification;

- (void)didReceivePauseTerminateNotification:(NSNotification *)notification;

@end

@implementation IMUTLibDefaultTimeSource {
    NSDate *_startDate;
    double _referenceTime;
}

- (instancetype)init {
    if (self = [super init]) {
        // Reset the start date on start and resume notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveStartResumeNotification:)
                                                     name:IMUTLibWillStartNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveStartResumeNotification:)
                                                     name:IMUTLibWillPauseNotification
                                                   object:nil];

        // Running is NO when we receive pause and terminate notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceivePauseTerminateNotification:)
                                                     name:IMUTLibDidResumeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceivePauseTerminateNotification:)
                                                     name:IMUTLibWillTerminateNotification
                                                   object:nil];
    }

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark IMUTLibTimeSource protocol

+ (NSNumber *)timeSourcePreference {
    return [NSNumber numberWithUnsignedLong:IMUTLibDefaultTimeSourcePreference];
}

- (NSString *)timeSourceInfo {
    return @"default";
}

- (NSDate *)startDate {
    @synchronized (self) {
        return _startDate;
    }
}

- (NSTimeInterval)intervalSinceClockStart {
    if (_startDate) {
        return uptime() - _referenceTime;
    }

    return 0;
}

#pragma mark Private

- (void)didReceiveStartResumeNotification:(NSNotification *)notification {
    @synchronized (self) {
        _startDate = [NSDate date];
        _referenceTime = uptime();
        [self.timeSourceDelegate clockDidStartAtDate:_startDate];
    }
}

- (void)didReceivePauseTerminateNotification:(NSNotification *)notification {
    @synchronized (self) {
        if (_startDate) {
            _startDate = nil;
            [self.timeSourceDelegate clockDidStopAfterTimeInterval:[self intervalSinceClockStart]];
            _referenceTime = 0;
        }
    }
}

@end
