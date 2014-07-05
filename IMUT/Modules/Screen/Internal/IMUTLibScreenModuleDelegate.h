@protocol IMUTLibScreenModuleDelegate

- (void)recorder:(NSObject *)recorder createdNewFrameAtTime:(NSTimeInterval)time;

- (void)recorder:(NSObject *)recorder willFinalizeCurrentMediaFileAtPath:(NSString *)path;

@end
