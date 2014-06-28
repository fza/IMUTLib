#import "IMUTLibConstants.h"
#import "Macros.h"

// Exceptions
NSString *const IMUTLibInitWithoutConfigrationException = BUNDLE_IDENTIFIER_CONCAT("init-without-configuration");
NSString *const IMUTLibFailedToEnableModuleException = BUNDLE_IDENTIFIER_CONCAT("failed-to-enable-module");
NSString *const IMUTLibFailedToReadConfigurationException = BUNDLE_IDENTIFIER_CONCAT("failed-to-read-config-file");


// Notifications
NSString *const IMUTLibWillStartNotification = BUNDLE_IDENTIFIER_CONCAT("will-start");
NSString *const IMUTLibWillPauseNotification = BUNDLE_IDENTIFIER_CONCAT("will-pause");
NSString *const IMUTLibDidResumeNotification = BUNDLE_IDENTIFIER_CONCAT("did-resume");
NSString *const IMUTLibWillTerminateNotification = BUNDLE_IDENTIFIER_CONCAT("will-terminate");
NSString *const IMUTLibModuleRegistryDidFreezeNotification = BUNDLE_IDENTIFIER_CONCAT("registry.did-freeze");
NSString *const IMUTLibDidSessionCreateNotification = BUNDLE_IDENTIFIER_CONCAT("session.did-create");
NSString *const IMUTLibClockDidStartNotification = BUNDLE_IDENTIFIER_CONCAT("timesource.did-start");
NSString *const IMUTLibClockDidStopNotification = BUNDLE_IDENTIFIER_CONCAT("timesource.will-stop");
NSString *const IMUTLibEventSynchronizerDidStartNotification = BUNDLE_IDENTIFIER_CONCAT("synchronizer.did-start");


// Configuration keys
NSString *const kIMUTLibConfigAutostart = @"autostart";
NSString *const kIMUTLibConfigKeepUnfinishedFiles = @"keepUnfinishedFiles";
NSString *const kIMUTLibConfigSynchronizationTimeInterval = @"synchronizationTimeInterval";


// Delta entity type keys
NSString *const kIMUTLibDeltaEntityTypeAbsolute = @"abs";
NSString *const kIMUTLibDeltaEntityTypeDelta = @"delta";
NSString *const kIMUTLibDeltaEntityTypeStatus = @"status";
NSString *const kIMUTLibDeltaEntityTypeMixed = @"mixed";
NSString *const kIMUTLibDeltaEntityTypeOther = @"other";
NSString *const kIMUTLibDeltaEntityTypeUnknown = @"unknown";


// Log packet type keys
NSString *const kIMUTLibLogPacketTypeSessionInit = @"session-init";
NSString *const kIMUTLibLogPacketTypeSync = @"sync";
NSString *const kIMUTLibLogPacketTypeEvents = @"events";
NSString *const kIMUTLibLogPacketTypeFinalize = @"finalize";


// Misc constants
NSString* const kkUnknown = @"unknown";
NSString *const kSessionId = @"sessionId";
NSString *const kTimeSource = @"timeSource";
NSString *const kStartDate = @"startDate";
NSString *const kSessionDuration = @"sessionDuration";
NSString *const kIMUTLibInitialEventsPacket = @"initial";
NSString *const kIMUTNextSortingNumber = @"nextSortingNumber";
NSString *const IMUTLibDefaultPlistFilename = @"IMUT.plist";
NSString *const IMUTLibTempFileExtension = @"tmp";
NSString *const IMUTMetaFileBasename = @"imut--meta";


// Initializers for special constants (non-compile-time constants)
CONSTRUCTOR {
    cNO = [NSNumber numberWithBool:NO];
    cYES = [NSNumber numberWithBool:YES];
}
