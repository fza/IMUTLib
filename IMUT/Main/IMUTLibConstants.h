#import <Foundation/Foundation.h>

// Exceptions
NSString *const IMUTLibInitWithoutConfigrationException;
NSString *const IMUTLibFailedToEnableModuleException;
NSString *const IMUTLibFailedToReadConfigurationException;


// Notifications
NSString *const IMUTLibWillStartNotification;
NSString *const IMUTLibWillPauseNotification;
NSString *const IMUTLibDidResumeNotification;
NSString *const IMUTLibWillTerminateNotification;
NSString *const IMUTLibModuleRegistryDidFreezeNotification;
NSString *const IMUTLibDidSessionCreateNotification;
NSString *const IMUTLibClockDidStartNotification;
NSString *const IMUTLibClockDidStopNotification;
NSString *const IMUTLibEventSynchronizerDidStartNotification;


// Configuration keys
NSString *const kIMUTLibConfigAutostart;
NSString *const kIMUTLibConfigKeepUnfinishedFiles;
NSString *const kIMUTLibConfigSynchronizationTimeInterval;


// Delta entity type keys
NSString *const kIMUTLibDeltaEntityTypeAbsolute;
NSString *const kIMUTLibDeltaEntityTypeDelta;
NSString *const kIMUTLibDeltaEntityTypeStatus;
NSString *const kIMUTLibDeltaEntityTypeMixed;
NSString *const kIMUTLibDeltaEntityTypeOther;
NSString *const kIMUTLibDeltaEntityTypeUnknown;


// Log packet type keys
NSString *const kIMUTLibLogPacketTypeSessionInit;
NSString *const kIMUTLibLogPacketTypeSync;
NSString *const kIMUTLibLogPacketTypeEvents;
NSString *const kIMUTLibLogPacketTypeFinalize;


// Misc constants
NSString* const kUnknown;
NSString *const kSessionId;
NSString *const kTimeSource;
NSString *const kStartDate;
NSString *const kSessionDuration;
NSString *const kIMUTLibInitialEventsPacket;
NSString *const kIMUTNextSortingNumber;
NSString *const IMUTLibDefaultPlistFilename;
NSString *const IMUTLibTempFileExtension;
NSString *const IMUTMetaFileBasename;


// Special constants
NSNumber *cNO;
NSNumber *cYES;
