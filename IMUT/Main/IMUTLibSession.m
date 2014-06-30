#import "IMUTLibConstants.h"
#import "IMUTLibSession.h"
#import "IMUTLibUtil.h"
#import "IMUTLibMetaData.h"
#import "IMUTLibFunctions.h"

@interface IMUTLibSession ()

@property(atomic, readwrite, retain) NSDate *cachedStartDate;
@property(atomic, readwrite, assign) NSTimeInterval cachedDuration;

- (instancetype)initWithTimeSource:(id <IMUTLibTimeSource>)timeSource;

@end

@implementation IMUTLibSession {
    NSTimeInterval _cachedDuration;
    NSDate *_cachedStartDate;
}

@dynamic sessionDuration;
@dynamic startDate;

DESIGNATED_INIT

+ (instancetype)sessionWithTimeSource:(id <IMUTLibTimeSource>)timeSource {
    return [[self alloc] initWithTimeSource:timeSource];
}

- (NSTimeInterval)sessionDuration {
    if (self.cachedDuration) {
        return self.cachedDuration;
    }

    return _timeSource.intervalSinceClockStart;
}

- (NSDate *)startDate {
    return self.cachedStartDate;
}

- (void)invalidate {
    _invalid = YES;
}

#pragma mark IMUTLibTimeSourceDelegate

- (void)clockDidStartAtDate:(NSDate *)startDate {
    self.cachedStartDate = [startDate copy];

    [IMUTLibUtil postNotificationName:IMUTLibClockDidStartNotification
                               object:self
                             userInfo:@{
                                 kSessionId : self.sessionId,
                                 kTimeSource : self.timeSource,
                                 kStartDate : _cachedStartDate
                             }
                         onMainThread:NO
                        waitUntilDone:YES];
}

- (void)clockDidStopAfterTimeInterval:(NSTimeInterval)timeInterval {
    self.cachedDuration = timeInterval;

    [IMUTLibUtil postNotificationName:IMUTLibClockDidStopNotification
                               object:self
                             userInfo:@{
                                 kSessionId : self.sessionId,
                                 kTimeSource : self.timeSource,
                                 kSessionDuration : @(timeInterval)
                             }
                         onMainThread:NO
                        waitUntilDone:YES];
}

#pragma mark Private

- (instancetype)initWithTimeSource:(id <IMUTLibTimeSource>)timeSource {
    if (self = [super init]) {
        _invalid = NO;
        _sessionId = randomString(10);
        _timeSource = timeSource;
        _timeSource.timeSourceDelegate = self;
        _sortingNumber = [[IMUTLibMetaData sharedInstance] numberAndIncr:kIMUTNextSortingNumber
                                                                 default:@0
                                                                isDouble:NO];
    }

    return self;
}

@end
