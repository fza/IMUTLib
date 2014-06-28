#import <Foundation/Foundation.h>
#import "Macros.h"

@interface IMUTLibMetaData : NSObject

SINGLETON_INTERFACE

- (id)objectForKey:(NSString *)key default:(id)defaultValue;

- (NSNumber *)numberAndIncr:(NSString *)key
                    default:(NSNumber *)defaultValue
                   isDouble:(BOOL)isDouble;

- (void)setObject:(id)object forKey:(NSString *)key;

@end
