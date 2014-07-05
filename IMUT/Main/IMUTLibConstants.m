#import "Macros.h"
#import "IMUTLibConstants.h"

// Exceptions
NSString *const IMUTLibInitWithoutConfigrationException = BUNDLE_IDENTIFIER_CONCAT("init-without-configuration");
NSString *const IMUTLibFailedToEnableModuleException = BUNDLE_IDENTIFIER_CONCAT("failed-to-enable-module");
NSString *const IMUTLibFailedToReadConfigurationException = BUNDLE_IDENTIFIER_CONCAT("failed-to-read-config-file");


// Notifications
NSString *const IMUTLibWillStartNotification = BUNDLE_IDENTIFIER_CONCAT("will-start");
NSString *const IMUTLibWillPauseNotification = BUNDLE_IDENTIFIER_CONCAT("will-_pause");
NSString *const IMUTLibDidResumeNotification = BUNDLE_IDENTIFIER_CONCAT("did-resume");
NSString *const IMUTLibWillTerminateNotification = BUNDLE_IDENTIFIER_CONCAT("will-terminate");
NSString *const IMUTLibModuleRegistryWillFreezeNotification = BUNDLE_IDENTIFIER_CONCAT("registry.will-freeze");
NSString *const IMUTLibModuleRegistryDidFreezeNotification = BUNDLE_IDENTIFIER_CONCAT("registry.did-freeze");
NSString *const IMUTLibDidCreateSessionNotification = BUNDLE_IDENTIFIER_CONCAT("session.created");
NSString *const IMUTLibDidInvalidateSessionNotification = BUNDLE_IDENTIFIER_CONCAT("session.invalidated");
NSString *const IMUTLibClockDidStartNotification = BUNDLE_IDENTIFIER_CONCAT("timer.did-start");
NSString *const IMUTLibClockDidStopNotification = BUNDLE_IDENTIFIER_CONCAT("timer.will-stop");
NSString *const IMUTLibEventSynchronizerDidStartNotification = BUNDLE_IDENTIFIER_CONCAT("synchronizer.did-start");
NSString *const IMUTLibEventSynchronizerWillStopNotification = BUNDLE_IDENTIFIER_CONCAT("synchronizer.will-stop");


// Configuration keys
NSString *const kIMUTLibConfigAutostart = @"autostart";
NSString *const kIMUTLibConfigKeepUnfinishedFiles = @"keepUnfinishedFiles";
NSString *const kIMUTLibConfigSynchronizationTimeInterval = @"synchronizationTimeInterval";


// Delta entity type keys
NSString *const kIMUTLibPersistableEntityTypeAbsolute = @"abs";
NSString *const kIMUTLibPersistableEntityTypeDelta = @"delta";
NSString *const kIMUTLibPersistableEntityTypeStatus = @"status";
NSString *const kIMUTLibPersistableEntityTypeMixed = @"mixed";
NSString *const kIMUTLibPersistableEntityTypeOther = @"other";
NSString *const kIMUTLibPersistableEntityTypeUnknown = @"unknown";


// Log packet type keys
NSString *const kIMUTLibLogPacketTypeSessionInit = @"session-init";
NSString *const kIMUTLibLogPacketTypeSync = @"sync";
NSString *const kIMUTLibLogPacketTypeEvents = @"events";
NSString *const kIMUTLibLogPacketTypeFinal = @"final";


// Misc constants
NSString *const kDefault = @"default";
NSString *const kUnknown = @"unknown";
NSString *const kParamAbsoluteDateTime = @"abs-date-time";
NSString *const kParamTimebaseInfo = @"timebase";
NSString *const kEntityMarking = @"mark";
NSString *const kEntityMarkInitial = @"initial";
NSString *const kEntityMarkFinal = @"final";
NSString *const kDefaultSessionTimer = @"default timer";
NSString *const kNextSortingNumber = @"nextSortingNumber";
NSString *const kDefaultPlistFilename = @"IMUT.plist";
NSString *const kTempFileExtension = @"tmp";
NSString *const kMetaFileBasename = @"imut--meta";


// Initializers for special constants (non-compile-time constants)
CONSTRUCTOR {
    numNO = [NSNumber numberWithBool:NO];
    numYES = [NSNumber numberWithBool:YES];
}
