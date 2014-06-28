#import "IMUTLibConstants.h"
#import "IMUTLibSession.h"
#import "IMUTLibUtil.h"
#import "IMUTLibMetaData.h"

@interface IMUTLibSession ()

@property(nonatomic, readwrite, retain) NSString *sid;
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
    @synchronized (self) {
        [IMUTLibUtil postNotificationOnMainThreadWithNotificationName:IMUTLibClockDidStartNotification
                                                               object:self.timeSource
                                                        waitUntilDone:YES];
    }
}

- (void)clockDidStop {
    @synchronized (self) {
        [IMUTLibUtil postNotificationOnMainThreadWithNotificationName:IMUTLibClockDidStopNotification
                                                               object:self.timeSource
                                                        waitUntilDone:YES];
    }
}

#pragma mark Private

- (instancetype)initWithTimeSource:(id <IMUTLibTimeSource>)timeSource {
    if (self = [super init]) {
        self.sid = [IMUTLibUtil randomStringWithLength:10];
        self.timeSource = timeSource;
        self.timeSource.timeSourceDelegate = self;
        self.sortingNumber = [[IMUTLibMetaData sharedInstance] numberAndIncr:kIMUTNextSortingNumber
                                                                     default:@0
                                                                    isDouble:NO];

        if ([(NSObject *) timeSource respondsToSelector:@selector(denoteAsPrimaryTimeSource)]) {
            [timeSource denoteAsPrimaryTimeSource];
        }

        _invalid = NO;

        IMUTLogMain(@"Session ID: %@", self.sid);
    }

    return self;
}

@end
