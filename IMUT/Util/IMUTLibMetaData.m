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

- (id)objectForKey:(NSString *)key default:(id)defaultValue {
    @synchronized (self) {
        [self readMetadata];
        id value = _metadata[key];

        return value != nil ? value : defaultValue;
    }
}

- (NSNumber *)numberAndIncr:(NSString *)key default:(NSNumber *)defaultValue isDouble:(BOOL)isDouble {
    id value = [self objectForKey:key default:defaultValue];

    if (value != nil && [value isKindOfClass:[NSNumber class]]) {
        NSNumber *newValue;
        if (isDouble) {
            newValue = [NSNumber numberWithDouble:[value doubleValue] + 1];
        } else {
            newValue = [NSNumber numberWithInteger:[value integerValue] + 1];
        }

        [self setObject:newValue forKey:key];

        return value;
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
        NSString *metadataFilename = [IMUTMetaFileBasename stringByAppendingPathExtension:@"plist"];
        absoluteMetadataFilePath = [imutPath stringByAppendingPathComponent:metadataFilename];
    }

    return absoluteMetadataFilePath;
}

@end
