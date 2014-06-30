#import "IMUTLibFileManager.h"
#import "IMUTLibLogPacketStreamWriter.h"
#import "IMUTLibFunctions.h"
#import "IMUTLibTimer.h"
#import "IMUTLibJSONStreamEncoder.h"
#import "Macros.h"

@interface IMUTLibLogPacketStreamWriter ()

@property(nonatomic, readwrite, retain) NSString *basename;

- (id)initWithBasename:(NSString *)basename packetEncoder:(id <IMUTLibLogPacketStreamEncoder>)encoder;

- (void)run;

- (void)createFileHandle;

+ (id <IMUTLibLogPacketStreamEncoder>)encoderForType:(IMUTLibLogPacketEncoderType)encoderType;

@end

@implementation IMUTLibLogPacketStreamWriter {
    // Retain self, because the original owner may release early (i.e. the synchronizer), what
    // would cause this class to be deallocated before the current log file could have been
    // finalized.
    __strong id _strongSelf;

    id <IMUTLibLogPacketStreamEncoder> _encoder;

    NSFileHandle *_currentFileHandle;
    NSString *_currentAbsoluteFilePath;

    unsigned long _packetSequence;
    NSMutableArray *_packetQueue;

    dispatch_queue_t _dispatchQueue;
    IMUTLibTimer *_timer;
}

DESIGNATED_INIT

+ (instancetype)writerWithBasename:(NSString *)basename packetEncoderType:(IMUTLibLogPacketEncoderType)encoderType {
    return [[self alloc] initWithBasename:basename packetEncoder:[self encoderForType:encoderType]];
}

- (void)newFile {
    if (_currentFileHandle) {
        [self closeFileWaitUntilDone:YES];
    }

    dispatch_sync(_dispatchQueue, ^{
        // Maintain self reference
        _strongSelf = self;

        // The packet backlog and next sequence number
        _packetQueue = [NSMutableArray array];
        _packetSequence = 0;

        // Open new file
        [self createFileHandle];

        // Resume the timer
        [_timer resume];
    });
}

- (void)enqueuePacket:(id <IMUTLibLogPacket>)logPacket {
    @synchronized (_packetQueue) {
        [_packetQueue addObject:logPacket];
    }
}

- (void)closeFileWaitUntilDone:(BOOL)waitUntilDone {
    dispatch_sync(_dispatchQueue, ^{
        if(!_currentFileHandle || [_timer paused]) {
            return;
        }

        // Encode all packets in the queue and pause the timer
        [_timer fireAndPause];

        // Write out the complete backlog
        [_encoder endEncoding];

        // Close and rename file
        [_currentFileHandle closeFile];
        [IMUTLibFileManager renameTemporaryFileAtPath:_currentAbsoluteFilePath];
        _currentFileHandle = nil;
        _currentAbsoluteFilePath = nil;

        // Resign self reference
        _strongSelf = nil;
    });
}

# pragma mark IMUTLibLogPacketEncoderDelegate

- (void)encoder:(id <IMUTLibLogPacketStreamEncoder>)encoder encodedData:(NSData *)data {
    [_currentFileHandle writeData:data];
}

#pragma mark Private

- (id)initWithBasename:(NSString *)basename packetEncoder:(id <IMUTLibLogPacketStreamEncoder>)encoder {
    if (self = [super init]) {
        // The basename to use for all filenames
        _basename = basename;

        // Setup the packet encoder
        _encoder = encoder;
        _encoder.delegate = self;
        [_encoder beginEncoding];

        // Setup timer to encode and write log packets
        _dispatchQueue = makeDispatchQueue(@"log_writer", DISPATCH_QUEUE_SERIAL, DISPATCH_QUEUE_PRIORITY_LOW);
        _timer = repeatingTimer(5.0, self, @selector(run), _dispatchQueue, NO);
    }

    return self;
}

- (void)run {
    if (_packetQueue.count) {
        // Switch packet queues
        NSMutableArray *writePacketQueue;
        @synchronized (_packetQueue) {
            writePacketQueue = [_packetQueue copy];
            [_packetQueue removeAllObjects];
        }

        // Notify the delegate
        if ([(NSObject *) self.delegate respondsToSelector:@selector(logWriter:willWriteLogPackets:)]) {
            [self.delegate logWriter:self willWriteLogPackets:&writePacketQueue];
        }

        // Write packets via the encoder
        for (id <IMUTLibLogPacket> logPacket in writePacketQueue) {
            [_encoder encodeObject:[logPacket dictionaryWithSequence:_packetSequence++]];
        }
    }
}

- (void)createFileHandle {
    _currentAbsoluteFilePath = [IMUTLibFileManager absoluteFilePathWithBasename:self.basename
                                                                      extension:@"json"
                                                               ensureUniqueness:YES
                                                                    isTemporary:YES];

    _currentFileHandle = [NSFileHandle fileHandleForWritingAtPath:_currentAbsoluteFilePath];

    if (!_currentFileHandle) {
        [[NSFileManager defaultManager] createFileAtPath:_currentAbsoluteFilePath
                                                contents:nil
                                              attributes:nil];
        _currentFileHandle = [NSFileHandle fileHandleForWritingAtPath:_currentAbsoluteFilePath];
    }

    [_currentFileHandle seekToEndOfFile];
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
