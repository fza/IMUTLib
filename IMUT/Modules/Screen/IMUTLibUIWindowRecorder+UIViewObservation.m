#import <UIKit/UIKit.h>
#import "IMUTLibUIWindowRecorder+UIViewObservation.h"
#import "IMUTLibScreenModuleConstants.h"
#import "IMUTLibUtil.h"
#import "Macros.h"
#import "NSObject+IMUTLibClassExtension.h"

static UIView *activeUIStatusBar;
static UITextField *activeSecureUITextField;

#pragma mark UIStatusBar handling

@interface IMUTLibUIStatusBarInternal : UIView

@end

@implementation IMUTLibUIStatusBarInternal

- (void)setFrame:(CGRect)frame {
    if (!activeUIStatusBar || activeUIStatusBar != self) {
        activeUIStatusBar = self;

        [IMUTLibUtil postNotificationOnMainThreadWithNotificationName:UIStatusBarChangedNotification
                                                               object:self
                                                        waitUntilDone:NO];
    }

    [self original_setFrame:frame];
}

// stand-in dummy method
- (void)original_setFrame:(CGRect)frame {
}

@end

#pragma mark UITextField handling

@interface IMUTLibUITextFieldInternal : UITextField

@end

@implementation IMUTLibUITextFieldInternal

- (BOOL)becomeFirstResponder {
    BOOL isFirstResponder = [self original_becomeFirstResponder];

    if (isFirstResponder && [self isSecureTextEntry]) {
        activeSecureUITextField = self;

        [IMUTLibUtil postNotificationOnMainThreadWithNotificationName:UISecureTextFieldBecameFirstResponder
                                                               object:self
                                                        waitUntilDone:NO];
    }

    return isFirstResponder;
}

// stand-in dummy method
- (BOOL)original_becomeFirstResponder {
    return YES;
}

- (BOOL)resignFirstResponder {
    BOOL resignedFirstResponder = [self original_resignFirstResponder];

    if (resignedFirstResponder && activeSecureUITextField == self) {
        activeSecureUITextField = nil;

        [IMUTLibUtil postNotificationOnMainThreadWithNotificationName:UISecureTextFieldResignedFirstResponder
                                                               object:self
                                                        waitUntilDone:NO];
    }

    return resignedFirstResponder;
}

// stand-in dummy method
- (BOOL)original_resignFirstResponder {
    return YES;
}

@end

#pragma mark IMUTLibUIWindowRecorder+UIViewObservation

@implementation IMUTLibUIWindowRecorder (UIViewObservation)

+ (UIView *)activeUIStatusBar {
    return activeUIStatusBar;
}

+ (UITextField *)activeSecureUITextField {
    return activeSecureUITextField;
}

@end

CONSTRUCTOR {
    [objc_getClass("UIStatusBar") __IMUT_integrateMethodFromSourceClass:[IMUTLibUIStatusBarInternal class]
                                                     withSourceSelector:@selector(setFrame:)];

    [UITextField __IMUT_integrateMethodFromSourceClass:[IMUTLibUITextFieldInternal class]
                                    withSourceSelector:@selector(becomeFirstResponder)];

    [UITextField __IMUT_integrateMethodFromSourceClass:[IMUTLibUITextFieldInternal class]
                                    withSourceSelector:@selector(resignFirstResponder)];
}
