#import <objc/runtime.h>
#import <Foundation/Foundation.h>

// Main logging facility
#define IMUTLogMain(...) { NSLog(@"*** IMUT *** %@", [NSString stringWithFormat:__VA_ARGS__]); }

// Standard logging facility
#define IMUTLog(...) { NSLog(@"[%@] %@", NSStringFromClass([self class]), [NSString stringWithFormat:__VA_ARGS__]); }
#define IMUTLogC(...) { NSLog(@"[%@] %@", [NSString stringWithUTF8String:__FUNCTION__], [NSString stringWithFormat:__VA_ARGS__]); }

// Debug logging facility
#ifdef DEBUG
#define IMUTLogDebug(...) { IMUTLog(__VA_ARGS__); }
#define IMUTLogDebugC(...) { IMUTLogC(__VA_ARGS__); }
#define IMUTLogDebugModule(moduleName, ...) { IMUTLogDebug(@"Module \"%@\": %@", moduleName, [NSString stringWithFormat:__VA_ARGS__]); }
#define IMUTLogDebugModuleDirect(...) { IMUTLogDebug(@"Module \"%@\": %@", [[self class] moduleName], [NSString stringWithFormat:__VA_ARGS__]); }
#else
    #define IMUTLogDebug(...)
    #define IMUTLogDebugC(...)
    #define IMUTLogDebugModule(moduleName, ...)
    #define IMUTLogDebugModuleDirect(...)
#endif

// Immutable NSSet literal $(...)
#define $(...) [NSSet setWithObjects:__VA_ARGS__, nil]

// Mutable NSSet literal
#define $MS(...) [NSMutableSet setWithSet:__VA_ARGS__]

// Mutable dictionary literal
#define $MD(...) [NSMutableDictionary dictionaryWithDictionary:__VA_ARGS__]

// Mutable array literal
#define $MA(...) [NSMutableArray arrayWithArray:__VA_ARGS__]

// Make bundle identifier strings
#define BUNDLE_IDENTIFIER_CONCAT(STRING) @ BUNDLE_IDENTIFIER @"." @ STRING

// Conveniences
#define __DESIGNATED_INIT_METHOD_BODY \
    NSAssert(false, @"You cannot init this class (\"%@\") with the \"init\" method. Instead, use a designated initializer.", NSStringFromClass([self class])); \
    return nil;

#define DESIGNATED_INIT \
- (id)init { \
    __DESIGNATED_INIT_METHOD_BODY \
}

#define _ABSTRACT_CLASS_IF_STATEMENT(CLASS) \
    if ([self class] == objc_getClass([@ CLASS UTF8String])) { \
        NSAssert(false, @"You cannot init this class (\"%@\") directly. Instead, use a subclass.", @ CLASS); \
        return nil; \
    }

#define ABSTRACT_CLASS(CLASS) \
- (id)init { \
    _ABSTRACT_CLASS_IF_STATEMENT(CLASS) \
    return [super init]; \
}

#define ABSTRACT_CLASS_DESIGNATED_INIT(CLASS) \
- (id)init { \
    _ABSTRACT_CLASS_IF_STATEMENT(CLASS) else { \
        __DESIGNATED_INIT_METHOD_BODY \
    } \
    return [super init]; \
}

// Singleton
#define SINGLETON_INTERFACE + (instancetype)sharedInstance;
#define SINGLETON \
SINGLETON_INTERFACE { \
    static id sharedInstance = nil; \
    static dispatch_once_t onceToken; \
    dispatch_once(&onceToken, ^{ \
        if (!sharedInstance) sharedInstance = [self new]; \
    }); \
    return sharedInstance; \
}

// Constructor (static initializer)
#define CONSTRUCTOR __attribute__((constructor)) static void init()

// Exceptions
#define MethodNotImplementedException(methodName) { \
        @throw [NSException exceptionWithName:BUNDLE_IDENTIFIER_CONCAT("method-not-implemented") \
                                       reason:[NSString stringWithFormat:@"Method not implemented: \"%@\" in class: \"%@\".", methodName, NSStringFromClass([self class])] \
                                     userInfo:nil]; \
}

// Manual retain and release
// @seehttp://stackoverflow.com/questions/7792622/manual-retain-with-arc
#define AntiARCRetain(...) void *retainedThing = (__bridge_retained void *)__VA_ARGS__; retainedThing = retainedThing
#define AntiARCRelease(...) void *retainedThing = (__bridge void *) __VA_ARGS__; id unretainedThing = (__bridge_transfer id)retainedThing; unretainedThing = nil

// C Assert with message
#define assertMsg(cond, msg) assert( (msg, cond) );

// Misc
#define COUNT_ARRAY_ELEMENTS(array, type) sizeof(array) / sizeof(type)
