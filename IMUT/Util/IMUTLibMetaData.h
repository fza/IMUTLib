#import <Foundation/Foundation.h>

#import "Macros.h"

@interface IMUTLibMetaData : NSObject

SINGLETON_INTERFACE

- (NSObject *)objectForKey:(NSString *)key default:(NSObject *)defaultValue;

- (NSNumber *)numberAndIncr:(NSString *)key
                    default:(NSNumber *)defaultValue
                   isDouble:(BOOL)isDouble;

- (void)setObject:(NSObject *)object forKey:(NSString *)key;

@end
