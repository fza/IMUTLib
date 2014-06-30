#import "IMUTLibFunctions.h"
#import "IMUTLibConstants.h"
#import "Macros.h"

static inline dispatch_queue_t _makeDispatchQueue(NSString *name, dispatch_queue_attr_t attr) {
    name = [NSString stringWithFormat:BUNDLE_IDENTIFIER_CONCAT("%@"), name];
    return dispatch_queue_create([name cStringUsingEncoding:NSASCIIStringEncoding], attr);
};

dispatch_queue_t mainImutDispatchQueue(long priority) {
    static dispatch_queue_t highPriorityQueue;
    static dispatch_queue_t defaultPriorityQueue;
    static dispatch_queue_t lowPriorityQueue;

    switch (priority) {
        case DISPATCH_QUEUE_PRIORITY_HIGH:
            if (!highPriorityQueue) {
                highPriorityQueue = _makeDispatchQueue(@"main.high", DISPATCH_QUEUE_CONCURRENT);
                dispatch_set_target_queue(highPriorityQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
            }

            return highPriorityQueue;

        case DISPATCH_QUEUE_PRIORITY_LOW:
            if (!lowPriorityQueue) {
                lowPriorityQueue = _makeDispatchQueue(@"main.low", DISPATCH_QUEUE_CONCURRENT);
                dispatch_set_target_queue(lowPriorityQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));
            }

            return lowPriorityQueue;

        default:
            if (!lowPriorityQueue) {
                defaultPriorityQueue = _makeDispatchQueue(@"main.default", DISPATCH_QUEUE_CONCURRENT);
                dispatch_set_target_queue(defaultPriorityQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
            }

            return defaultPriorityQueue;
    }
}

dispatch_queue_t makeDispatchQueue(NSString *name, dispatch_queue_attr_t attr, long priority) {
    dispatch_queue_t queue = _makeDispatchQueue(name, attr);
    dispatch_set_target_queue(queue, mainImutDispatchQueue(priority));

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

    return dispatch_group_wait(group, timeout) == 0;
}

NSNumber *oBool(BOOL flag) {
    if (flag) {
        return numYES;
    }

    return numNO;
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

void IMUTfree(void *ptr) {
    free(ptr);
}
