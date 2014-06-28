#import "IMUTLibConstants.h"
#import "IMUTLibSession.h"
#import "IMUTLibUtil.h"
#import "IMUTLibMetaData.h"
#import "IMUTLibFunctions.h"

@interface IMUTLibSession ()

@property(nonatomic, readwrite, retain) NSString *sessionId;
@property(nonatomic, readwrite, weak) id <IMUTLibTimeSource> timeSource;
@property(nonatomic, readwrite, retain) NSNumber *sortingNumber;

- (instancetype)initWithTimeSource:(id <IMUTLibTimeSource>)timeSource;

@end

@implementation IMUTLibSession

@synthesize invalid = _invalid;

- (BOOL)timeSourceRunning {
    return [self.timeSource startDate] != nil;
}

+ (instancetype)sessionWithTimeSource:(id <IMUTLibTimeSource>)timeSource {
    return [[self alloc] initWithTimeSource:timeSource];
}

- (void)invalidate {
    _invalid = YES;
}

#pragma mark IMUTLibTimeSourceDelegate

- (void)clockDidStartAtDate:(NSDate *)startDate {
    [IMUTLibUtil postNotificationOnMainThreadWithNotificationName:IMUTLibClockDidStartNotification
                                                           object:self
                                                         userInfo:@{
                                                             kSessionId : self.sessionId,
                                                             kTimeSource : self.timeSource,
                                                             kStartDate : [startDate copy]
                                                         }
                                                    waitUntilDone:YES];
}

- (void)clockDidStopAfterTimeInterval:(NSTimeInterval)timeInterval {
    [IMUTLibUtil postNotificationOnMainThreadWithNotificationName:IMUTLibClockDidStopNotification
                                                           object:self
                                                         userInfo:@{
                                                             kSessionId : self.sessionId,
                                                             kTimeSource : self.timeSource,
                                                             kSessionDuration : @(timeInterval)
                                                         }
                                                    waitUntilDone:YES];
}

#pragma mark Private

- (instancetype)initWithTimeSource:(id <IMUTLibTimeSource>)timeSource {
    if (self = [super init]) {
        self.sessionId = randomString(10);
        self.timeSource = timeSource;
        self.timeSource.timeSourceDelegate = self;
        self.sortingNumber = [[IMUTLibMetaData sharedInstance] numberAndIncr:kIMUTNextSortingNumber
                                                                     default:@0
                                                                    isDouble:NO];

        if ([(NSObject *) timeSource respondsToSelector:@selector(denoteAsPrimaryTimeSource)]) {
            [timeSource denoteAsPrimaryTimeSource];
        }

        _invalid = NO;

        IMUTLogMain(@"Session ID: %@", self.sessionId);
    }

    return self;
}

@end
