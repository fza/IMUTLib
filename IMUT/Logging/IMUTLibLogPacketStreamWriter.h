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

// The delegate (= event synchronizer)
@property(nonatomic, readwrite, weak) id <IMUTLibStreamLogWriterDelegate> delegate;

+ (instancetype)writerWithBasename:(NSString *)basename packetEncoderType:(IMUTLibLogPacketEncoderType)encoderType;

- (void)newFile;

- (void)enqueuePacket:(id <IMUTLibLogPacket>)logPacket;

- (void)closeFileWaitUntilDone:(BOOL)waitUntilDone;

@end
