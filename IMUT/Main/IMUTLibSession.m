#import "IMUTLibSession.h"

#import "Macros.h"
#import "IMUTLibUtil.h"
#import "IMUTLibConstants.h"
#import "IMUTLibFunctions.h"
#import "IMUTLibMetaData.h"

@interface IMUTLibSession ()

- (instancetype)initWithTimer:(NSObject <IMUTLibSessionTimer> *)timer;

@end

@implementation IMUTLibSession {
    BOOL _started;
    BOOL _stopping;
}

@dynamic duration;
@dynamic timerInfo;

DESIGNATED_INIT

+ (instancetype)sessionWithTimer:(NSObject <IMUTLibSessionTimer> *)timer {
    return [[self alloc] initWithTimer:timer];
}

- (NSTimeInterval)duration {
    return _timer.duration;
}

- (NSString *)timerInfo {
    return [[_timer class] description];
}

- (void)startWithCompletionBlock:(void (^)(BOOL started))completed {
    @synchronized (self) {
        if (!_invalid && !_started) {
            _started = YES;

            [_timer startTickingWithCompletionBlock:^(BOOL started){
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    @synchronized (self) {
                        if (!_invalid && started) {
                            _startDate = [NSDate date];

                            [IMUTLibUtil postNotificationName:IMUTLibClockDidStartNotification
                                                       object:self
                                                 onMainThread:NO
                                                waitUntilDone:YES];

                            completed(YES);
                        } else {
                            completed(NO);
                        }
                    }
                });
            }];
        } else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                completed(NO);
            });
        }
    }
}

- (void)stopWithCompletionBlock:(void (^)(BOOL stopped))completed {
    @synchronized (self) {
        if (!_invalid && _started && !_stopping) {
            _stopping = YES;

            [_timer stopTickingWithCompletionBlock:^(BOOL stopped){
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    @synchronized (self) {
                        [IMUTLibUtil postNotificationName:IMUTLibClockDidStopNotification
                                                   object:self
                                             onMainThread:NO
                                            waitUntilDone:YES];

                        _stopping = NO;

                        completed(YES);
                    }
                });
            }];

            _invalid = YES;
        } else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                completed(NO);
            });
        }
    }
}

#pragma mark Private

- (instancetype)initWithTimer:(NSObject <IMUTLibSessionTimer> *)timer {
    if (self = [super init]) {
        _invalid = NO;
        _started = NO;
        _sessionId = randomString(10);
        _timer = timer;
        _sortingNumber = [[IMUTLibMetaData sharedInstance] numberAndIncr:kNextSortingNumber
                                                                 default:@0
                                                                isDouble:NO];
    }

    return self;
}

@end
