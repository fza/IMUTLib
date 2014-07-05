#import <Foundation/Foundation.h>

#import "IMUTLibLogPacketStreamEncoder.h"
#import "IMUTLibLogPacket.h"

@protocol IMUTLibStreamLogWriterDelegate;

typedef NS_ENUM(NSUInteger, IMUTLibLogPacketEncoderType) {
    IMUTLibLogPacketEncoderJSON = 1
};

@interface IMUTLibLogPacketStreamWriter : NSObject <IMUTLibLogPacketStreamEncoderDelegate>

// The basename for files to create
@property(nonatomic, readonly, retain) NSString *basename;

// The delegate (= event synchronizer)
@property(nonatomic, readwrite, weak) NSObject <IMUTLibStreamLogWriterDelegate> *delegate;

+ (instancetype)writerWithBasename:(NSString *)basename packetEncoderType:(IMUTLibLogPacketEncoderType)encoderType;

- (void)createFile;

- (void)enqueuePacket:(IMUTLibLogPacket *)logPacket;

- (void)closeFile;

@end

@protocol IMUTLibStreamLogWriterDelegate

@optional
// Passing the log packets array as pointer to pointer of object so that the receiver may
// completely replace the array object if necessary.
- (void)logWriter:(IMUTLibLogPacketStreamWriter *)logWriter willWriteLogPackets:(NSArray **)logPackets;

@end

