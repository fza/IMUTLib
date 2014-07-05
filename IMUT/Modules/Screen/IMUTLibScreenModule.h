#import <Foundation/Foundation.h>

#import "IMUTLibModule.h"
#import "IMUTLibScreenModuleDelegate.h"
#import "IMUTLibPollingVideoSource.h"

@interface IMUTLibScreenModule : IMUTLibModule

@property(nonatomic, readonly, retain) IMUTLibMediaWriter *mediaWriter;

@property(nonatomic, readonly, retain) IMUTLibPollingVideoSource *videoSource;

@property(nonatomic, readwrite, retain) NSObject <IMUTLibScreenModuleDelegate> *delegate;

- (BOOL)startRecording;

- (void)stopRecording;

@end
