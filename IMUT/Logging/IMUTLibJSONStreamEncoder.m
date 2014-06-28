#import "IMUTLibJSONStreamEncoder.h"

static NSString *arrayStart = @"[";
static NSString *separator = @",";
static NSString *indentation = @"\n  ";
static NSString *arrayClose = @"\n]";

@interface IMUTLibJSONStreamEncoder ()

- (void)writeString:(NSString *)string;

@end

@implementation IMUTLibJSONStreamEncoder {
    BOOL _beganEncoding;
    BOOL _closed;
    BOOL _encodedFirstObject;
}

- (instancetype)init {
    if (self = [super init]) {
        _beganEncoding = NO;
        _closed = NO;
        _encodedFirstObject = NO;
    }

    return self;
}

- (void)beginEncoding {
    @synchronized (self) {
        if (_closed) {
            return;
        }

        if (!_beganEncoding) {
            [self writeString:arrayStart];
            _beganEncoding = YES;
        }
    }
}

- (void)encodeObject:(id)object {
    @synchronized (self) {
        if (_closed) {
            return;
        }

        [self beginEncoding];

        NSError *error;
        NSData *rawJSONData = [NSJSONSerialization dataWithJSONObject:object
                                                              options:NSJSONWritingPrettyPrinted
                                                                error:&error];

        if (error == nil) {
            if (_encodedFirstObject) {
                [self writeString:separator];
            }

            NSString *rawDataString = [[NSString alloc] initWithData:rawJSONData
                                                            encoding:NSUTF8StringEncoding];

            [rawDataString enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
                [self writeString:indentation];
                [self writeString:line];
            }];

            _encodedFirstObject = YES;
        } else if ([(NSObject *) self.delegate respondsToSelector:@selector(encoder:encodingError:)]) {
            [self.delegate encoder:self encodingError:error];
        }
    }
}

- (void)endEncoding {
    @synchronized (self) {
        if (_beganEncoding && !_closed) {
            [self writeString:arrayClose];
            _beganEncoding = NO;
            _closed = YES;
            _encodedFirstObject = NO;
        }
    }
}

#pragma mark Private

- (void)writeString:(NSString *)string {
    [self.delegate encoder:self encodedData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

@end
