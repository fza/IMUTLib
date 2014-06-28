#import <Foundation/Foundation.h>
#import "IMUTLibLogPacket.h"
#import "IMUTLibLogPacketStreamEncoder.h"

@class IMUTLibLogPacketStreamWriter;

typedef NS_ENUM(NSUInteger, IMUTLibLogPacketEncoderType) {
    IMUTLibLogPacketEncoderJSON = 1
};

@protocol IMUTLibStreamLogWriterDelegate

@optional
// Passing the log packets array as pointer to pointer so that the receiver may
// completely replace the array object if necessary.
- (void)logWriter:(IMUTLibLogPacketStreamWriter *)logWriter willWriteLogPackets:(NSArray **)packetQueue;

@end

@interface IMUTLibLogPacketStreamWriter : NSObject <IMUTLibLogPacketStreamEncoderDelegate>

// The basename for files to create
@property(nonatomic, readonly, retain) NSString *basename;

// A flag to pause/resume writing
@property(atomic, readwrite, assign) BOOL mayWrite;

// The time interval to write out enqueued log packets
@property(nonatomic, readwrite, assign) NSTimeInterval writeInterval;

// The delegate (= event synchronizer)
@property(nonatomic, readwrite, weak) id <IMUTLibStreamLogWriterDelegate> delegate;

+ (instancetype)writerWithBasename:(NSString *)basename
                         sessionId:(NSString *)sessionId
                 packetEncoderType:(IMUTLibLogPacketEncoderType)encoderType;

+ (instancetype)writerWithBasename:(NSString *)basename
                         sessionId:(NSString *)sessionId
                     packetEncoder:(id <IMUTLibLogPacketStreamEncoder>)encoder;

- (void)enqueuePacket:(id <IMUTLibLogPacket>)logPacket;

- (void)closeFile;

@end
