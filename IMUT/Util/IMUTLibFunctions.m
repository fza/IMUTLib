#import "IMUTLibFunctions.h"
#import "IMUTLibConstants.h"
#import "Macros.h"

dispatch_queue_t makeDispatchQueue(NSString *name, dispatch_queue_attr_t attr, long priority) {
    name = [NSString stringWithFormat:BUNDLE_IDENTIFIER_CONCAT("%@"), name];
    dispatch_queue_t queue = dispatch_queue_create([name UTF8String], attr);
    dispatch_set_target_queue(queue, dispatch_get_global_queue(priority, 0));

    return queue;
}

NSNumber *oBool(BOOL flag) {
    if (flag) {
        return cYES;
    }

    return cNO;
}
