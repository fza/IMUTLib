#import <Foundation/Foundation.h>

#import "IMUTLibSessionTimer.h"

@interface IMUTLibSession : NSObject

// The id string of this session
@property(nonatomic, readonly, retain) NSString *sessionId;

// The start date of the session
@property(nonatomic, readonly, retain) NSDate *startDate;

// The duration of the session
@property(nonatomic, readonly) NSTimeInterval duration;

// The backing time source
@property(nonatomic, readonly, weak) NSObject <IMUTLibSessionTimer> *timer;

// Get the timer info string directly
@property(nonatomic, readonly, weak) NSString *timerInfo;

// The sorting number used to generate file names
@property(nonatomic, readonly, retain) NSNumber *sortingNumber;

// Wether the session is invalid / was stopped
@property(nonatomic, readonly) BOOL invalid;

+ (instancetype)sessionWithTimer:(NSObject <IMUTLibSessionTimer> *)timer;

- (void)startWithCompletionBlock:(void (^)(BOOL started))completed;

- (void)stopWithCompletionBlock:(void (^)(BOOL stopped))completed;

@end
