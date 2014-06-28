#import <Foundation/Foundation.h>
#import "IMUTLibMediaStreamWriter.h"
#import "Macros.h"

// This is a container for all configured media stream writers
@interface IMUTLibMediaStreamManager : NSObject

SINGLETON_INTERFACE

// Returns a writer with a specific key, or if key is nil returns an anonymous writer.
// Basename may never be omitted.
- (IMUTLibMediaStreamWriter *)writerWithBasename:(NSString *)name;

@end
