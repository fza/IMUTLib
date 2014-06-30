#import <Foundation/Foundation.h>
#import "IMUTLibTimeSource.h"

@protocol IMUTLibTimeSource;

@interface IMUTLibSession : NSObject <IMUTLibTimeSourceDelegate>

// The id string of this session
@property(nonatomic, readonly, retain) NSString *sessionId;

// The start date of the session
@property(nonatomic, readonly, retain) NSDate *startDate;

// The duration of the session
@property(nonatomic, readonly) NSTimeInterval sessionDuration;

// The backing time source
@property(nonatomic, readonly, weak) id <IMUTLibTimeSource> timeSource;

// The sorting number used to generate file names
@property(nonatomic, readonly, retain) NSNumber *sortingNumber;

// Wether the session is invalid / was closed
@property(nonatomic, readonly) BOOL invalid;

+ (instancetype)sessionWithTimeSource:(id <IMUTLibTimeSource>)timeSource;

- (BOOL)start;

- (void)invalidate;

@end
