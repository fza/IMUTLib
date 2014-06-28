#import <Foundation/Foundation.h>

@protocol IMUTLibSourceEvent

- (NSString *)eventName;

- (NSDictionary *)parameters;

@end
