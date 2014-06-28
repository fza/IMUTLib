#import "IMUTLibFunctions.h"
#import "IMUTLibConstants.h"
#import "Macros.h"

dispatch_queue_t makeDispatchQueue(NSString *name, dispatch_queue_attr_t attr, long priority) {
    name = [NSString stringWithFormat:BUNDLE_IDENTIFIER_CONCAT("%@"), name];
    dispatch_queue_t queue = dispatch_queue_create([name UTF8String], attr);
    dispatch_set_target_queue(queue, dispatch_get_global_queue(priority, 0));

    return queue;
}

// The basic idea is to enqueue another block and to wait until it is executed,
// which is then interpreted as the queue being idle. Note that it is of course
// possible that there may be blocks inserted into the queue after we placed the
// marker block!
BOOL waitForDispatchQueueToBecomeIdle(dispatch_queue_t queue, dispatch_time_t timeout) {
    dispatch_group_t group = dispatch_group_create();

    dispatch_group_enter(group);
    dispatch_async(queue, ^{
        dispatch_group_leave(group);
    });

    BOOL isIdle = dispatch_group_wait(group, timeout) == 0;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    });

    return isIdle;
}

NSNumber *oBool(BOOL flag) {
    if (flag) {
        return cYES;
    }

    return cNO;
}

NSTimeInterval uptime() {
    return [[NSProcessInfo processInfo] systemUptime];
}

NSString *randomString(NSUInteger length) {
    static NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

    NSMutableString *randomString = [NSMutableString stringWithCapacity:length];
    for (NSUInteger i = 0; i < length; i++) {
        [randomString appendFormat:@"%C",
                                   [letters characterAtIndex:arc4random_uniform((unsigned int) [letters length])]];
    }

    return randomString;
}

NSString *iso8601StringFromDate(NSDate *date) {
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.timeZone = [NSTimeZone localTimeZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];

    return [dateFormatter stringFromDate:date];
};
