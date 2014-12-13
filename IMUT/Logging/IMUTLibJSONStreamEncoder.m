#import <libkern/OSAtomic.h>

#import "IMUTLibJSONStreamEncoder.h"

static NSString *arrayStart = @"[";
static NSString *separator = @",";
static NSString *indentation = @"\n  ";
static NSString *arrayClose = @"\n]";

@interface IMUTLibJSONStreamEncoder ()

// Return a string as NSData object to the delegate
- (void)writeString:(NSString *)string;

@end

@implementation IMUTLibJSONStreamEncoder {
    BOOL _began;
    BOOL _closed;
    BOOL _encodedFirstObject;

    OSSpinLock _lock; // The encoder is locked while writing out its data
}

- (instancetype)init {
    if (self = [super init]) {
        _fileExtension = @"json";
        _lock = OS_SPINLOCK_INIT;
    }

    return self;
}

- (void)beginEncoding {
    _began = NO;
    _closed = NO;
    _encodedFirstObject = NO;
}

- (void)encodeObject:(id)object {
    if (!_closed) {
        NSError *error;
        NSData *rawJSONData = [NSJSONSerialization dataWithJSONObject:object
                                                              options:NSJSONWritingPrettyPrinted
                                                                error:&error];

        if (!error) {
            NSString *rawDataString = [[NSString alloc] initWithData:rawJSONData
                                                            encoding:NSUTF8StringEncoding];

            NSMutableString *dataString = [NSMutableString new];
            [rawDataString enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
                [dataString appendString:indentation];
                [dataString appendString:line];
            }];

            OSSpinLockLock(&_lock);
            if (_closed) {
                return;
            }

            if (!_began) {
                _began = YES;
                [dataString insertString:arrayStart atIndex:0];
            }

            if (_encodedFirstObject) {
                [dataString insertString:separator atIndex:0];
            }

            _encodedFirstObject = YES;

            [self writeString:dataString];
            OSSpinLockUnlock(&_lock);
        } else if ([self.delegate respondsToSelector:@selector(encoder:encodingError:)]) {
            [self.delegate encoder:self encodingError:error];
        }
    }
}

- (void)endEncoding {
    if (!_began || _closed) {
        return;
    }

    OSSpinLockLock(&_lock);
    _closed = YES;

    [self writeString:arrayClose];
    OSSpinLockUnlock(&_lock);
}

#pragma mark Private

- (void)writeString:(NSString *)string {
    [self.delegate encoder:self encodedData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

@end
