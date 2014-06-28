#import <Foundation/Foundation.h>
#import <dispatch/queue.h>

// Convenience method to create a new dispatch queue
dispatch_queue_t makeDispatchQueue(NSString *name, dispatch_queue_attr_t attr, long priority);

// Wait for a dispatch queue until it becomes idle
BOOL waitForDispatchQueueToBecomeIdle(dispatch_queue_t queue, dispatch_time_t timeout);

// Convenience method that returns a static NSNumber instance for a boolean value
NSNumber *oBool(BOOL flag);

// This is by far the most important function as it returns the system uptime with
// sub-millisecond precision (according to tests) and is guaranteed to return
// monolithic increasing data. It is independent of the system time, which is
// subject to run even backwards when certain events occur. (i.e. mobile cell change
// or manual reset by the user)
NSTimeInterval uptime();

// Returns an alphanumeric string of arbitrary data
NSString *randomString(NSUInteger length);

// Formats a date according to ISO 8601 including timezone info
NSString *iso8601StringFromDate(NSDate *date);
