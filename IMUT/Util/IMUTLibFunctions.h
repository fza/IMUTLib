#import <Foundation/Foundation.h>
#import <dispatch/queue.h>


// Functions to work with dispatch queues -->

// The main dispatch all IMUT specific operations should run in, if
// they don't need to perform actions on the main thread. Having all
// sorts of operations running in the same dispatch queue we can easily
// invalidate these queues when we would need to in later versions.
// Currently this is only for convenience. Modules must not use this
// method, instead use the function `makeDispatchQueue`.
dispatch_queue_t mainImutDispatchQueue(long priority);

// Convenience method to create a new dispatch queue that is tied to the
// main imut dispatch queue
dispatch_queue_t makeDispatchQueue(NSString *name, dispatch_queue_attr_t attr, long priority);

// Wait for a dispatch queue until it becomes idle
// Warning: Do not use when the application is about to terminate!
BOOL waitForDispatchQueueToBecomeIdle(dispatch_queue_t queue, dispatch_time_t timeout);






// Memory management -->

void *IMUTAllocate(size_t size);

void IMUTDeallocate(void *ptr);





// Misc. functions -->

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
