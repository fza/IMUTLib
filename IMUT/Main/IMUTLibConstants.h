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
NSString *const IMUTLibModuleRegistryWillFreezeNotification;
NSString *const IMUTLibModuleRegistryDidFreezeNotification;
NSString *const IMUTLibDidCreateSessionNotification;
NSString *const IMUTLibDidInvalidateSessionNotification;
NSString *const IMUTLibClockDidStartNotification;
NSString *const IMUTLibClockDidStopNotification;
NSString *const IMUTLibEventSynchronizerDidStartNotification;
NSString *const IMUTLibEventSynchronizerWillStopNotification;


// Configuration keys
NSString *const kIMUTLibConfigAutostart;
NSString *const kIMUTLibConfigKeepUnfinishedFiles;
NSString *const kIMUTLibConfigSynchronizationTimeInterval;


// Delta entity type keys
NSString *const kIMUTLibPersistableEntityTypeAbsolute;
NSString *const kIMUTLibPersistableEntityTypeDelta;
NSString *const kIMUTLibPersistableEntityTypeStatus;
NSString *const kIMUTLibPersistableEntityTypeMixed;
NSString *const kIMUTLibPersistableEntityTypeOther;
NSString *const kIMUTLibPersistableEntityTypeUnknown;


// Log packet type keys
NSString *const kIMUTLibLogPacketTypeSessionInit;
NSString *const kIMUTLibLogPacketTypeSync;
NSString *const kIMUTLibLogPacketTypeEvents;
NSString *const kIMUTLibLogPacketTypeFinal;


// Misc constants
NSString *const kDefault;
NSString *const kUnknown;
NSString *const kParamAbsoluteDateTime;
NSString *const kParamTimebaseInfo;
NSString *const kEntityMarking;
NSString *const kEntityMarkInitial;
NSString *const kEntityMarkFinal;
NSString *const kDefaultSessionTimer;
NSString *const kNextSortingNumber;
NSString *const kDefaultPlistFilename;
NSString *const kTempFileExtension;
NSString *const kMetaFileBasename;


// Special constants
NSNumber *numNO;
NSNumber *numYES;
