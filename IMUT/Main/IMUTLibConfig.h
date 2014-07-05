#import <Foundation/Foundation.h>

@interface IMUTLibConfig : NSObject

+ (instancetype)configFromPlistFileWithName:(NSString *)plistFile;

- (instancetype)initWithPlistFile:(NSString *)plistFileName;

- (instancetype)initWithConfigDict:(NSDictionary *)configDict;

- (NSDictionary *)moduleConfigs;

- (NSObject *)valueForConfigKey:(NSString *)key default:(NSObject *)defaultValue;

@end
