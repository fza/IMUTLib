#import <Foundation/Foundation.h>
#import "IMUTLibTimeSource.h"

@interface IMUTLibSession : NSObject <IMUTLibTimeSourceDelegate>

// The id string of this session
@property(nonatomic, readonly, retain) NSString *sid;

// The backing time source
@property(nonatomic, readonly, weak) id <IMUTLibTimeSource> timeSource;

// The sorting number used to generate file names
@property(nonatomic, readonly, retain) NSNumber *sortingNumber;

// Wether the session is invalid / was closed
@property(nonatomic, readonly, assign) BOOL invalid;

+ (instancetype)sessionWithTimeSource:(id <IMUTLibTimeSource>)timeSource;

- (BOOL)timeSourceRunning;

- (void)invalidate;

@end
