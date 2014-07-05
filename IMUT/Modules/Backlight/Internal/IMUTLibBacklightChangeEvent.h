#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#import "IMUTLibSourceEvent.h"

@interface IMUTLibBacklightChangeEvent : NSObject <IMUTLibSourceEvent>

- (instancetype)initWithBrightness:(CGFloat)brightness;

- (CGFloat)brightness;

@end
