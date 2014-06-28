#import <Foundation/Foundation.h>

@interface IMUTLibConfig : NSObject

+ (instancetype)configFromPlistFileWithName:(NSString *)plistFile;

- (instancetype)initWithPlistFile:(NSString *)plistFileName;

- (instancetype)initWithConfigDict:(NSDictionary *)configDict;

- (NSDictionary *)moduleConfigs;

- (NSSet *)enabledModuleNames;

- (id)valueForConfigKey:(NSString *)key default:(id)defaultValue;

@end
