#import <Foundation/Foundation.h>
#import <dispatch/queue.h>

// Convenience method to create a new dispatch queue
dispatch_queue_t makeDispatchQueue(NSString *name, dispatch_queue_attr_t attr, long priority);

// Convenience method that returns a static NSNumber instance for a boolean value
NSNumber *oBool(BOOL flag);
