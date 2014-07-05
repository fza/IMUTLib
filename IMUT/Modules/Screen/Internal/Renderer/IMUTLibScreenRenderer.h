#import <Foundation/Foundation.h>

#import "IMUTLibPollingVideoSource.h"

@protocol IMUTLibScreenRendererDelegate;

@interface IMUTLibScreenRenderer : NSObject <IMUTLibVideoRenderer>

@property(nonatomic, readwrite, weak) NSObject <IMUTLibScreenRendererDelegate> *delegate;

+ (instancetype)rendererWithConfig:(NSDictionary *)config;

@end

@protocol IMUTLibScreenRendererDelegate

@optional
- (void)renderer:(IMUTLibScreenRenderer *)renderer createdNewFrameAtTime:(NSTimeInterval)time;

@end
