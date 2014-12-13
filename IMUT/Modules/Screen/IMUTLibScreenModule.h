#import <Foundation/Foundation.h>

#import "IMUTLibModule.h"
#import "IMUTLibScreenModuleDelegate.h"
#import "IMUTLibScreenVideoSource.h"

@interface IMUTLibScreenModule : IMUTLibModule

@property(nonatomic, readonly, retain) IMUTLibMediaWriter *mediaWriter;

@property(nonatomic, readonly, retain) IMUTLibScreenVideoSource *videoSource;

@property(nonatomic, readwrite, retain) NSObject <IMUTLibScreenModuleDelegate> *delegate;

- (BOOL)startRecording;

- (void)stopRecording;

@end
