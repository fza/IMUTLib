#import <Foundation/Foundation.h>

@interface IMUTLibDeltaEntity : NSObject

@property(nonatomic, readonly) NSString * key;
@property(nonatomic, readonly) NSDictionary *parameters;
@property(nonatomic, readonly) id sourceEvent;

+ (instancetype)entityWithKey:(NSString *)key parameters:(NSDictionary *)parameters sourceEvent:(id)sourceEvent;

@end
