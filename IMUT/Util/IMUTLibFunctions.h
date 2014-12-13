#import <Foundation/Foundation.h>
#import <CoreMedia/CMSync.h>

// ########
// Functions to work with dispatch queues -->

// Convenience method to create a new dispatch queue that is tied to the
// main imut dispatch queue
dispatch_queue_t makeDispatchQueue(NSString *name, dispatch_queue_attr_t attr, long priority);

// Creates an new dispatch queue with a target that is explicitly different from
// the IMUT-internal queues. The dispatch priority is borrowed from the target
// queue.
dispatch_queue_t makeDispatchQueueWithTargetQueue(NSString *name, dispatch_queue_attr_t attr, dispatch_queue_t targetQueue);

// ########
// Misc. functions -->

// YES if the class or its parent classes conform to a protocol
BOOL classConformsToProtocol(Protocol *theProtocol, Class theClass);

// Checks if a metaclass is a subclass of a another metaclass
BOOL classIsSubclassOfClass(Class subClass, Class ancestorClass);

// Convenience method that returns a static NSNumber instance for a boolean value
NSNumber *oBool(BOOL flag);

// Returns a string of random alphanumeric data
NSString *randomString(NSUInteger length);

// Formats a date according to ISO 8601 including timezone info
NSString *iso8601StringFromDate(NSDate *date);

// Formats a time interval
NSString *formatTimeInterval(NSTimeInterval timeInterval);

// Formats a sample time
NSString *formatCMTime(CMTime time);
