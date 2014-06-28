#import <Foundation/Foundation.h>

@interface IMUTLibFileManager : NSObject

// Returns the path to the "IMUT" directory inside the application owned library directory and
// ensured that this directory exists
+ (NSString *)absoluteImutDirectoryPath;

// The absolute path to a file with a specific basename and extension that is optionally ensured to
// be unique
+ (NSString *)absoluteFilePathWithBasename:(NSString *)basename
                                 extension:(NSString *)extension
                          ensureUniqueness:(BOOL)ensureUniqueness
                               isTemporary:(BOOL)isTemporary;

// Remove all files older than a specific date
+ (void)removeAllFilesCreatedBeforeDate:(NSDate *)date;

// Remove unfinalized (temporary) files
+ (void)removeTemporaryFiles;

// Rename a file with a temporary path suffix
+ (void)renameTemporaryFileAtPath:(NSString *)path;

// The free disk space
+ (NSNumber *)freeDiskSpaceInBytes;

@end
