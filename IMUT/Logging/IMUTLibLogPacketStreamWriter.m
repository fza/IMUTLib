#import "IMUTLibFileManager.h"
#import "IMUTLibLogPacketStreamWriter.h"
#import "IMUTLibFunctions.h"
#import "IMUTLibTimer.h"
#import "IMUTLibJSONStreamEncoder.h"
#import "Macros.h"

@interface IMUTLibLogPacketStreamWriter ()

@property(nonatomic, readwrite, retain) NSString *basename;

- (id)initWithBasename:(NSString *)basename sessionId:(NSString *)sessionId packetEncoder:(id <IMUTLibLogPacketStreamEncoder>)encoder;

- (NSFileHandle *)fileHandle;

- (void)timerFired;

+ (id <IMUTLibLogPacketStreamEncoder>)encoderForType:(IMUTLibLogPacketEncoderType)encoderType;

@end

@implementation IMUTLibLogPacketStreamWriter {
    // Retain self, because the original owner may release early (i.e. the synchronizer), what
    // would cause this class to be deallocated before the current log file could have been
    // finalized.
    __strong id _self;

    NSString *_sessionId;
    id <IMUTLibLogPacketStreamEncoder> _encoder;
    NSFileHandle *_currentFileHandle;
    NSString *_currentAbsoluteFilePath;
    unsigned long _packetSequenceNumber;
    NSMutableArray *_packetQueue;
    IMUTLibTimer *_timer;
    dispatch_queue_t _timerDispatchQueue;
}

DESIGNATED_INIT

@dynamic writeInterval;

- (NSTimeInterval)writeInterval {
    return _timer.timeInterval;
}

- (void)setWriteInterval:(NSTimeInterval)writeInterval {
    @synchronized (self) {
        _timer.timeInterval = writeInterval;
    }
}

+ (instancetype)writerWithBasename:(NSString *)basename sessionId:(NSString *)sessionId packetEncoderType:(IMUTLibLogPacketEncoderType)encoderType {
    id <IMUTLibLogPacketStreamEncoder> encoder = [self encoderForType:encoderType];

    return [self writerWithBasename:basename
                          sessionId:sessionId
                      packetEncoder:encoder];
}

+ (id)writerWithBasename:(NSString *)basename sessionId:(NSString *)sessionId packetEncoder:(id <IMUTLibLogPacketStreamEncoder>)encoder {
    return [[self alloc] initWithBasename:basename
                                sessionId:sessionId
                            packetEncoder:encoder];
}

- (void)enqueuePacket:(id <IMUTLibLogPacket>)logPacket {
    @synchronized (self) {
        if (_timer) {
            [_packetQueue addObject:logPacket];
        }
    }
}

- (void)closeFile {
    @synchronized (self) {
        // Invalidate the timer
        [_timer invalidate];
        _timer = nil;

        // Write out the complete backlog
        [self timerFired];
        [_encoder endEncoding];
        [_currentFileHandle closeFile];

        // Rename file
        [IMUTLibFileManager renameTemporaryFileAtPath:_currentAbsoluteFilePath];

        // Resign self reference for GC, so that this writer will be deallocated automatically
        _self = nil;
    }
}

# pragma mark IMUTLibLogPacketEncoderDelegate

- (void)encoder:(id <IMUTLibLogPacketStreamEncoder>)encoder encodedData:(NSData *)data {
    [[self fileHandle] writeData:data];
}

#pragma mark Private

- (id)initWithBasename:(NSString *)basename sessionId:(NSString *)sessionId packetEncoder:(id <IMUTLibLogPacketStreamEncoder>)encoder {
    if (self = [super init]) {
        self.basename = basename;
        self.mayWrite = YES;

        // The session id to use for all packets
        _sessionId = sessionId;

        // The packet encoder
        _encoder = encoder;
        _encoder.delegate = self;

        // Maintain self reference for GC
        _self = self;

        // The packet backlog and next sequence number
        _packetQueue = [NSMutableArray array];
        _packetSequenceNumber = 0;

        // Begin encoding
        [_encoder beginEncoding];

        // Setup timer to encode and write log packets
        _timerDispatchQueue = makeDispatchQueue(@"log_writer", DISPATCH_QUEUE_SERIAL, DISPATCH_QUEUE_PRIORITY_DEFAULT);
        _timer = [IMUTLibTimer scheduledTimerWithTimeInterval:5.0
                                                       target:self
                                                     selector:@selector(timerFired)
                                                     userInfo:nil
                                                      repeats:YES
                                                dispatchQueue:_timerDispatchQueue];
    }

    return self;
}

- (NSFileHandle *)fileHandle {
    if (!_currentFileHandle) {
        NSString *absolutePath = [IMUTLibFileManager absoluteFilePathWithBasename:self.basename
                                                                        extension:@"json"
                                                                 ensureUniqueness:YES
                                                                      isTemporary:YES];
        _currentAbsoluteFilePath = absolutePath;
        _currentFileHandle = [NSFileHandle fileHandleForWritingAtPath:absolutePath];
        if (!_currentFileHandle) {
            [[NSFileManager defaultManager] createFileAtPath:absolutePath
                                                    contents:nil
                                                  attributes:nil];
            _currentFileHandle = [NSFileHandle fileHandleForWritingAtPath:absolutePath];
        }

        [_currentFileHandle seekToEndOfFile];
    }

    return _currentFileHandle;
}

- (void)timerFired {
    if (self.mayWrite && _packetQueue.count) {
        NSMutableArray *tempPacketQueue;

        @synchronized (self) {
            // Switch packet queues
            tempPacketQueue = _packetQueue;
            _packetQueue = [NSMutableArray array];
        }

        if ([(NSObject *) self.delegate respondsToSelector:@selector(logWriter:willWriteLogPackets:)]) {
            [self.delegate logWriter:self willWriteLogPackets:&tempPacketQueue];
        }

        for (id <IMUTLibLogPacket> logPacket in tempPacketQueue) {
            [_encoder encodeObject:[logPacket dictionaryWithSessionId:_sessionId
                                                 packetSequenceNumber:_packetSequenceNumber++]];
        }
    }
}

+ (id <IMUTLibLogPacketStreamEncoder>)encoderForType:(IMUTLibLogPacketEncoderType)encoderType {
    switch (encoderType) {
        case IMUTLibLogPacketEncoderJSON:
            return [IMUTLibJSONStreamEncoder new];

        default:
            return nil;
    }
}

@end
