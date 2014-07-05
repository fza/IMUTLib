@class IMUTLibMediaWriter;

@protocol IMUTLibMediaWriterDelegate

@optional
- (void)mediaWriter:(IMUTLibMediaWriter *)mediaWriter didStartWritingFileAtPath:(NSString *)path;

- (void)mediaWriter:(IMUTLibMediaWriter *)mediaWriter willFinalizeFileAtPath:(NSString *)path;

- (void)mediaWriter:(IMUTLibMediaWriter *)mediaWriter didFinalizeFileAtPath:(NSString *)path;

@end
