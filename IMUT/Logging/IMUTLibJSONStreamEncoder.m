#import "IMUTLibJSONStreamEncoder.h"
#import "IMUTLibFunctions.h"

static NSString *arrayStart = @"[";
static NSString *separator = @",";
static NSString *indentation = @"\n  ";
static NSString *arrayClose = @"\n]";

@interface IMUTLibJSONStreamEncoder ()

- (void)writeString:(NSString *)string;

@end

@implementation IMUTLibJSONStreamEncoder {
    BOOL _began;
    BOOL _closed;
    BOOL _encodedFirstObject;
    dispatch_queue_t _encodingQueue;
}

- (instancetype)init {
    if (self = [super init]) {
        _began = NO;
        _closed = NO;
        _encodedFirstObject = NO;
        _encodingQueue = makeDispatchQueue(
            [NSString stringWithFormat:@"json_stream_encoder.%p", (__bridge void *) self],
            DISPATCH_QUEUE_SERIAL,
            DISPATCH_QUEUE_PRIORITY_LOW
        );
    }

    return self;
}

- (void)beginEncoding {
}

- (void)encodeObject:(id)object {
    if (!_closed) {
        NSError *error;
        NSData *rawJSONData = [NSJSONSerialization dataWithJSONObject:object
                                                              options:NSJSONWritingPrettyPrinted
                                                                error:&error];

        if (error == nil) {
            NSString *rawDataString = [[NSString alloc] initWithData:rawJSONData
                                                            encoding:NSUTF8StringEncoding];

            NSMutableString *dataString = [NSMutableString new];
            [rawDataString enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
                [dataString appendString:indentation];
                [dataString appendString:line];
            }];

            @synchronized (self) {
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

                dispatch_async(_encodingQueue, ^{
                    [self writeString:dataString];
                });
            }
        } else if ([(NSObject *) self.delegate respondsToSelector:@selector(encoder:encodingError:)]) {
            [self.delegate encoder:self encodingError:error];
        }
    }
}

- (void)endEncodingWaitUntilDone:(BOOL)waitUntilDone {
    if (!_began || _closed) {
        return;
    }

    @synchronized (self) {
        _closed = YES;
    }

    if (waitUntilDone) {
        BOOL doneEncoding;
        do {
            doneEncoding = waitForDispatchQueueToBecomeIdle(_encodingQueue, 5 * NSEC_PER_SEC);
        } while (!doneEncoding);

        [self writeString:arrayClose];
    } else {
        dispatch_async(_encodingQueue, ^{
            [self writeString:arrayClose];
        });
    }
}

#pragma mark Private

- (void)writeString:(NSString *)string {
    [self.delegate encoder:self encodedData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

@end
