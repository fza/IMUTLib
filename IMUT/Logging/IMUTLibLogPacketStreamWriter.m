#import <libkern/OSAtomic.h>

#import "Macros.h"
#import "IMUTLibLogPacketStreamWriter.h"
#import "IMUTLibTimer.h"
#import "IMUTLibFileManager.h"
#import "IMUTLibFunctions.h"
#import "IMUTLibJSONStreamEncoder.h"

@interface IMUTLibLogPacketStreamWriter ()

@property(nonatomic, readwrite, retain) NSString *basename;

- (instancetype)initWithBasename:(NSString *)basename packetEncoder:(NSObject <IMUTLibLogPacketStreamEncoder> *)encoder;

- (void)run;

- (void)createFileHandle;

+ (NSObject <IMUTLibLogPacketStreamEncoder> *)encoderForType:(IMUTLibLogPacketEncoderType)encoderType;

@end

@implementation IMUTLibLogPacketStreamWriter {
    // Retain self, because the original owner may release early (i.e. the synchronizer), what
    // would cause this class to be deallocated before the current log file could have been
    // finalized.
    __strong id _strongSelf;

    NSObject <IMUTLibLogPacketStreamEncoder> *_encoder;

    NSFileHandle *_currentFileHandle;
    NSString *_currentAbsoluteFilePath;

    unsigned long _packetSequence;
    NSMutableArray *_packetQueue;

    dispatch_queue_t _dispatchQueue;
    IMUTLibTimer *_timer;

    OSSpinLock _packetQueueLock;
}

DESIGNATED_INIT

+ (instancetype)writerWithBasename:(NSString *)basename packetEncoderType:(IMUTLibLogPacketEncoderType)encoderType {
    return [[self alloc] initWithBasename:basename packetEncoder:[self encoderForType:encoderType]];
}

- (void)createFile {
    if (_currentFileHandle) {
        [self closeFile];
    }

    dispatch_sync(_dispatchQueue, ^{
        // Maintain self reference
        _strongSelf = self;

        // The packet backlog and sequence number counter
        _packetQueue = [NSMutableArray array];
        _packetSequence = 0;

        // Open new file
        [self createFileHandle];

        // Resume the timer
        [_timer resume];
    });
}

- (void)enqueuePacket:(IMUTLibLogPacket *)logPacket {
    OSSpinLockLock(&_packetQueueLock);
    [_packetQueue addObject:logPacket];
    OSSpinLockUnlock(&_packetQueueLock);
}

- (void)closeFile {
    dispatch_sync(_dispatchQueue, ^{
        if (!_currentFileHandle || [_timer paused]) {
            return;
        }

        // Encode all packets in the queue and _pause the timer
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

- (void)encoder:(NSObject <IMUTLibLogPacketStreamEncoder> *)encoder encodedData:(NSData *)data {
    [_currentFileHandle writeData:data];
}

#pragma mark Private

- (instancetype)initWithBasename:(NSString *)basename packetEncoder:(NSObject <IMUTLibLogPacketStreamEncoder> *)encoder {
    if (self = [super init]) {
        // The basename to use for all filenames
        _basename = basename;

        // Setup the packet encoder
        _encoder = encoder;
        _encoder.delegate = self;

        // Setup timer to encode and write log packets
        _dispatchQueue = makeDispatchQueue(@"log_writer", DISPATCH_QUEUE_SERIAL, DISPATCH_QUEUE_PRIORITY_LOW);
        _timer = makeRepeatingTimer(5.0, self, @selector(run), _dispatchQueue, NO);

        // The lock that is acquired when operations on the packet queue are performed
        _packetQueueLock = OS_SPINLOCK_INIT;
    }

    return self;
}

- (void)run {
    if (_packetQueue.count) {
        // Switch packet queues
        NSMutableArray *writePackets;
        OSSpinLockLock(&_packetQueueLock);
        writePackets = [_packetQueue copy];
        [_packetQueue removeAllObjects];
        OSSpinLockUnlock(&_packetQueueLock);

        // Notify the delegate
        if ([self.delegate respondsToSelector:@selector(logWriter:willWriteLogPackets:)]) {
            [self.delegate logWriter:self willWriteLogPackets:&writePackets];
        }

        // Write packets via the encoder
        for (IMUTLibLogPacket *logPacket in writePackets) {
            [_encoder encodeObject:[logPacket dictionaryWithSequence:_packetSequence++]];
        }
    }
}

- (void)createFileHandle {
    _currentAbsoluteFilePath = [IMUTLibFileManager absoluteFilePathWithBasename:self.basename
                                                                      extension:[_encoder fileExtension]
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

    [_encoder beginEncoding];
}

+ (NSObject <IMUTLibLogPacketStreamEncoder> *)encoderForType:(IMUTLibLogPacketEncoderType)encoderType {
    switch (encoderType) {
        case IMUTLibLogPacketEncoderJSON:
            return [IMUTLibJSONStreamEncoder new];

        default:
            return nil;
    }
}

@end
