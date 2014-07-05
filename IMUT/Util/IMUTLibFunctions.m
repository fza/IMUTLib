#import <mach/mach_time.h>
#import <CoreMedia/CoreMedia.h>

#import "Macros.h"
#import "IMUTLibFunctions.h"
#import "IMUTLibConstants.h"

static inline dispatch_queue_t _makeDispatchQueue(NSString *name, dispatch_queue_attr_t attr) {
    name = [NSString stringWithFormat:BUNDLE_IDENTIFIER_CONCAT("%@"), name];
    return dispatch_queue_create([name cStringUsingEncoding:NSASCIIStringEncoding], attr);
};

dispatch_queue_t makeDispatchQueue(NSString *name, dispatch_queue_attr_t attr, long priority) {
    dispatch_queue_t queue = _makeDispatchQueue(name, attr);
    dispatch_set_target_queue(queue, dispatch_get_global_queue(priority, 0));

    return queue;
}

dispatch_queue_t makeDispatchQueueWithTargetQueue(NSString *name, dispatch_queue_attr_t attr, dispatch_queue_t targetQueue) {
    dispatch_queue_t queue = _makeDispatchQueue(name, attr);
    dispatch_set_target_queue(queue, targetQueue);

    return queue;
}

// The basic idea is to enqueue another block and to wait until it is executed,
// which is then interpreted as the queue being idle. Note that it is of course
// possible that there may be blocks inserted into the queue after we placed the
// marker block! TODO May be more efficient to use dispatch barriers?!
BOOL waitForDispatchQueueToBecomeIdle(dispatch_queue_t queue, dispatch_time_t timeout) {
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    dispatch_async(queue, ^{
        dispatch_group_leave(group);
    });

    return dispatch_group_wait(group, timeout) == 0;
}

BOOL classConformsToProtocol(Protocol *theProtocol, Class theClass) {
    do {
        if (class_conformsToProtocol(theClass, theProtocol)) {
            return YES;
        }
    } while ((theClass = class_getSuperclass(theClass)));

    return NO;
}

BOOL classIsSubclassOfClass(Class subClass, Class ancestorClass) {
    while ((subClass = class_getSuperclass(subClass))) {
        if (subClass == ancestorClass) {
            return YES;
        }
    }

    return NO;
}

NSNumber *oBool(BOOL flag) {
    if (flag) {
        return numYES;
    }

    return numNO;
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

NSString *formatTimeInterval(NSTimeInterval timeInterval) {
    unsigned int secs = (unsigned int) round(timeInterval);

    return [NSString stringWithFormat:@"%02d:%02d:%02d", secs / 3600, (secs / 60) % 60, secs % 60];
}

NSString *formatCMTime(CMTime time) {
    unsigned int secs = (unsigned int) floor(time.value / time.timescale);
    unsigned int pendingFrames = (unsigned int) (time.value % time.timescale);

    return [NSString stringWithFormat:@"%02d:%02d:%02d", secs / 3600, (secs / 60) % 60, pendingFrames];
}
