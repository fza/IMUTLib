#import "IMUTLibScreenModuleConstants.h"
#import "Macros.h"

// Module key
NSString *const kIMUTLibScreenModule = @"screenRecorder";

// Config keys
NSString *const kIMUTLibScreenModuleConfigHidePasswordInput = @"hidePasswordInput";
NSString *const kIMUTLibScreenModuleConfigUseLowResolution = @"useLowResolution";

// Event keys and param keys
NSString *const kIMUTLibScreenModuleRecorderStartEvent = @"screenRecorderStart";
NSString *const kIMUTLibScreenModuleRecorderStopEvent = @"screenRecorderStop";
NSString *const kIMUTLibScreenModuleRecorderStopEventParamDuration = @"duration";
NSString *const kIMUTLibScreenModuleRecorderStopEventParamFilename = @"file";

// Notifications
NSString *const UIStatusBarChangedNotification = BUNDLE_IDENTIFIER_CONCAT("uistatusbar.changed");
NSString *const UISecureTextFieldBecameFirstResponder = BUNDLE_IDENTIFIER_CONCAT("uitextfield.secure-field-became-first-responder");
NSString *const UISecureTextFieldResignedFirstResponder = BUNDLE_IDENTIFIER_CONCAT("uitextfield.secure-field-resigned-first-responder");
