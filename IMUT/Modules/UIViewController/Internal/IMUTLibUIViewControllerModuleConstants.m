#import "IMUTLibUIViewControllerModuleConstants.h"
#import "Macros.h"

// Module key
NSString *const kIMUTLibUIViewControllerModule = @"uiViewController";

// Config keys
NSString *const kIMUTLibUIViewControllerModuleConfigUseFullClassName = @"useFullClassName";

// Event keys and param keys
NSString *const kIMUTLibUIViewControllerChangeEvent = @"uiViewControllerChange";
NSString *const kIMUTLibUIViewControllerChangeEventParamFullClassName = @"class";
NSString *const kIMUTLibUIViewControllerChangeEventParamShortClassName = @"class-short";

// Notifications
NSString *const IMUTLibFrontMostViewControllerDidChangeNotification = BUNDLE_IDENTIFIER_CONCAT("frontmost-viewcontroller-changed");
