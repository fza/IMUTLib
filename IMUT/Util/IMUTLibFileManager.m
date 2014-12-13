#import "IMUTLibFileManager.h"
#import "IMUTLibSession.h"
#import "IMUTLibMain+Internal.h"
#import "IMUTLibConstants.h"

static NSCache *sequenceNumberCache;

@interface IMUTLibFileManager ()

+ (NSString *)shortBasenameOfFile:(NSString *)filename;

@end

@implementation IMUTLibFileManager

+ (void)initialize {
    sequenceNumberCache = [NSCache new];
}

+ (NSString *)absoluteImutDirectoryPath {
    static NSString *imutPath = nil;

    if (imutPath) {
        return imutPath;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *libraryURLs = [fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask];

    if ([libraryURLs count]) {
        @synchronized (self) {
            imutPath = [[[libraryURLs objectAtIndex:0] URLByAppendingPathComponent:@"IMUT" isDirectory:YES] path];

            if (![fileManager fileExistsAtPath:imutPath]) {
                NSError *error;
                [fileManager createDirectoryAtPath:imutPath
                       withIntermediateDirectories:YES
                                        attributes:nil
                                             error:&error];

                NSAssert(!error, @"Unable to create IMUT directory.");
            }
        }

        return imutPath;
    }

    return nil;
}

+ (NSString *)absoluteFilePathWithBasename:(NSString *)basename extension:(NSString *)extension ensureUniqueness:(BOOL)ensureUniqueness isTemporary:(BOOL)isTemporary {
    IMUTLibSession *session = [IMUTLibMain imut].session;

    NSAssert(session && !session.invalid, @"Unable to generate a unique filename as there is no valid IMUT session.");

    NSString *imutPath = [self absoluteImutDirectoryPath];
    if (!imutPath) {
        return nil;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *startNameWithString = session.sessionId;
    NSNumber *sortingNumber = session.sortingNumber;
    NSString *firstNamePart = [NSString stringWithFormat:@"%@_%@_%@", sortingNumber, startNameWithString, basename];
    NSString *filename = [NSString stringWithFormat:@"%@.%@", firstNamePart, extension];

    if (isTemporary) {
        extension = [extension stringByAppendingPathExtension:kTempFileExtension];
    }

    if (ensureUniqueness) {
        @synchronized (self) {
            int currentSequenceNumber = 0;
            NSNumber *currentSequenceNumberObj = [sequenceNumberCache objectForKey:filename];
            if (currentSequenceNumberObj) {
                currentSequenceNumber = (int) [currentSequenceNumberObj integerValue];
            }

            NSString *testPath;
            do {
                currentSequenceNumber++;
                testPath = [imutPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%d.%@",
                                                                                               firstNamePart,
                                                                                               currentSequenceNumber,
                                                                                               extension]];
            } while ([fileManager fileExistsAtPath:testPath]);

            [sequenceNumberCache setObject:@(currentSequenceNumber) forKey:filename];

            return testPath;
        }
    }

    return [imutPath stringByAppendingPathComponent:filename];
}

+ (void)removeAllFilesCreatedBeforeDate:(NSDate *)date {
    NSString *imutPath = [self absoluteImutDirectoryPath];
    if (imutPath) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:imutPath];
        NSString *filename, *basename, *absolutePath;
        NSError *error;
        NSDictionary *fileAttributes;
        NSMutableDictionary *filenamesToRecheck = [NSMutableDictionary dictionary];
        NSMutableArray *filenamesToCheck = [NSMutableArray arrayWithArray:[enumerator allObjects]];
        NSMutableSet *removedFileBasenames = [NSMutableSet set];
        unsigned long fileCount = filenamesToCheck.count;
        for (unsigned long i = 0; i < fileCount; i++) {
            filename = filenamesToCheck[i];
            basename = [self shortBasenameOfFile:filename];

            // Skip all non-IMUT files (though there shouldn't be any)
            if (basename) {
                absolutePath = [imutPath stringByAppendingPathComponent:filename];
                if ([fileManager isDeletableFileAtPath:absolutePath]) {
                    error = nil; // ARC
                    fileAttributes = [fileManager attributesOfItemAtPath:absolutePath error:&error];
                    if (!error && fileAttributes) {
                        if ([((NSDate *) fileAttributes[NSFileModificationDate]) laterDate:date] == date) {
                            [fileManager removeItemAtPath:absolutePath error:&error];
                            [removedFileBasenames addObject:basename];
                        } else {
                            [filenamesToRecheck setObject:filename forKey:basename];
                        }
                    }
                }
            }
        }

        // If we didn't delete all files, there may be companion files left that we should delete, too.
        // For example, there may be a log file that was deleted, but a video file with the same basename exists,
        // which was closed for writing shortly before the predicate date, so the above loop didn't delete it.
        // We now loop over all files that are still present and deletable, compare their basenames and unlink those
        // that match.
        for (basename in filenamesToRecheck) {
            if ([removedFileBasenames containsObject:basename]) {
                absolutePath = [imutPath stringByAppendingPathComponent:filenamesToRecheck[basename]];
                error = nil; // ARC
                [fileManager removeItemAtPath:absolutePath error:&error];
            }
        }
    }
}

+ (void)removeTemporaryFiles {
    NSString *imutPath = [self absoluteImutDirectoryPath];
    if (imutPath) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *filenames = [[fileManager enumeratorAtPath:imutPath] allObjects];
        [filenames enumerateObjectsUsingBlock:^(NSString *filename, NSUInteger idx, BOOL *stop) {
            if ([[filename pathExtension] isEqualToString:kTempFileExtension]) {
                NSError *error;
                [fileManager removeItemAtPath:[imutPath stringByAppendingPathComponent:filename] error:&error];
            }
        }];
    }
}

+ (NSString *)renameTemporaryFileAtPath:(NSString *)path {
    if (![[path pathExtension] isEqualToString:kTempFileExtension]) {
        return path;
    }

    if (![[path substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"/"]) {
        path = [[self absoluteImutDirectoryPath] stringByAppendingPathComponent:path];
    }

    NSError *error;
    NSString *finalPath = [path stringByDeletingPathExtension];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        [fileManager moveItemAtPath:path toPath:finalPath error:&error];
    }

    return error ? nil : finalPath;
}

// @see http://www.ios-developer.net/iphone-ipad-programmer/development/file-saving-and-loading/disk-information
+ (NSNumber *)freeDiskSpace {
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject]
                                                                                       error:&error];

    NSAssert(error == nil, @"Error obtaining file system info: %@", [error description]);

    return [dictionary objectForKey:NSFileSystemFreeSize];

    return nil;
}

#pragma mark Private

// IMUT filenames have the following form: 1_abcDEF123456z_screen.5.m4v
// 1             => sorting file number
// abcDEF123456z => session id
// screen        => arbitrary name chosen by the module
// 5             => number to ensure uniqueness of files
+ (NSString *)shortBasenameOfFile:(NSString *)filename {
    NSArray *basenameComponentsLeft = [filename componentsSeparatedByString:@"_"];
    if (basenameComponentsLeft.count == 3) {
        NSArray *basenameComponentsRight = [basenameComponentsLeft[2] componentsSeparatedByString:@"."];
        if (basenameComponentsRight.count == 3) {
            return [NSString stringWithFormat:@"%@_%@_%@.%@",
                                              basenameComponentsLeft[0],
                                              basenameComponentsLeft[1],
                                              basenameComponentsRight[0],
                                              basenameComponentsRight[1]];
        }
    }

    return nil;
}

@end
