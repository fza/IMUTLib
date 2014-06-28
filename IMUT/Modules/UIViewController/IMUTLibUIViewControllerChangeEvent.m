#import "IMUTLibUIViewControllerChangeEvent.h"
#import "IMUTLibUIViewControllerModuleConstants.h"

@implementation IMUTLibUIViewControllerChangeEvent {
    IMUTLibUIViewControllerModuleClassNameRepresentation _representation;
    NSString *_fullClassName;
    NSString *_shortClassName;
}

- (instancetype)initWithViewControllerFullClassName:(NSString *)fullClassName useRepresentation:(IMUTLibUIViewControllerModuleClassNameRepresentation)representation {
    if (self = [super init]) {
        _representation = representation;
        _fullClassName = fullClassName;

        if (![_fullClassName isEqualToString:@"UIViewController"]) {
            // Mangle the class name: UIImageViewController becomes "image"
            _shortClassName = [_fullClassName stringByReplacingOccurrencesOfString:@"UI"
                                                                        withString:@""
                                                                           options:NSLiteralSearch
                                                                             range:NSMakeRange(0, 2)];

            // If the class name starts with "UI" it is assumed to be a system view
            if (![_shortClassName isEqualToString:_fullClassName]) {
                _shortClassName = [NSString stringWithFormat:@"%@%@",
                                                             [[_shortClassName substringWithRange:NSMakeRange(0, 1)] lowercaseString],
                                                             [_shortClassName substringFromIndex:1]];
            }

            _shortClassName = [_shortClassName stringByReplacingOccurrencesOfString:@"ViewController"
                                                                         withString:@""
                                                                            options:NSLiteralSearch
                                                                              range:NSMakeRange(_shortClassName.length - 14, 14)];
        } else {
            _shortClassName = _fullClassName;
        }
    }

    return self;
}

- (NSString *)fullClassName {
    return _fullClassName;
}

- (NSString *)shortClassName {
    return _shortClassName;
}

#pragma mark IMUTLibSourceEvent protocol

- (NSString *)eventName {
    return kIMUTLibUIViewControllerChangeEvent;
}

- (NSDictionary *)parameters {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];

    switch (_representation) {
        case IMUTLibUIViewControllerModuleClassNameRepresentationFull:
            params[kIMUTLibUIViewControllerChangeEventParamFullClassName] = _fullClassName;

        default:
            params[kIMUTLibUIViewControllerChangeEventParamShortClassName] = _shortClassName;
    }

    return params;
}

@end
