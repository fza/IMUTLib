#import "IMUTLibMetaData.h"
#import "IMUTLibFileManager.h"
#import "IMUTLibConstants.h"

@interface IMUTLibMetaData ()

- (NSDictionary *)readMetadata;

- (void)writeMetadata;

- (NSString *)absoluteMetadataFilePath;

@end

@implementation IMUTLibMetaData {
    NSMutableDictionary *_metadata;
}

SINGLETON

- (NSObject *)objectForKey:(NSString *)key default:(NSObject *)defaultValue {
    @synchronized (self) {
        [self readMetadata];
        NSObject *value = _metadata[key];

        return value ?: defaultValue;
    }
}

- (NSNumber *)numberAndIncr:(NSString *)key default:(NSNumber *)defaultValue isDouble:(BOOL)isDouble {
    NSObject *value = [self objectForKey:key default:defaultValue];

    if (value && [value isKindOfClass:[NSNumber class]]) {
        NSNumber *newValue = isDouble ? @([(NSNumber *) value doubleValue] + 1) : @([(NSNumber *) value integerValue] + 1);
        [self setObject:newValue forKey:key];

        return (NSNumber *) value;
    }

    return nil;
}

- (void)setObject:(id)object forKey:(NSString *)key {
    @synchronized (self) {
        [self readMetadata];
        [_metadata setObject:object forKey:key];
        [self writeMetadata];
    }
}

#pragma mark Private

- (NSDictionary *)readMetadata {
    if (!_metadata) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *absoluteMetadataFilePath = [self absoluteMetadataFilePath];

        if ([fileManager fileExistsAtPath:absoluteMetadataFilePath]) {
            _metadata = [NSMutableDictionary dictionaryWithContentsOfFile:absoluteMetadataFilePath];
        }

        if (!_metadata) {
            // Default metadata
            _metadata = [NSMutableDictionary dictionary];
        }
    }

    return _metadata;
}

- (void)writeMetadata {
    @synchronized (self) {
        [_metadata writeToFile:[self absoluteMetadataFilePath] atomically:NO];
    }
}

- (NSString *)absoluteMetadataFilePath {
    static NSString *absoluteMetadataFilePath;

    if (!absoluteMetadataFilePath) {
        NSString *imutPath = [IMUTLibFileManager absoluteImutDirectoryPath];
        NSString *metadataFilename = [kMetaFileBasename stringByAppendingPathExtension:@"plist"];
        absoluteMetadataFilePath = [imutPath stringByAppendingPathComponent:metadataFilename];
    }

    return absoluteMetadataFilePath;
}

@end
