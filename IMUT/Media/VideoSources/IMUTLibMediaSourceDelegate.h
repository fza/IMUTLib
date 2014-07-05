@class IMUTLibMediaSource;

@protocol IMUTLibMediaSourceDelegate

- (void)mediaSourceWillBeginProducingSamples:(IMUTLibMediaSource *)mediaSource;

- (void)mediaSourceDidStopProducingSamples:(IMUTLibMediaSource *)mediaSource lastSampleTime:(CMTime)lastSampleTime;

@end
