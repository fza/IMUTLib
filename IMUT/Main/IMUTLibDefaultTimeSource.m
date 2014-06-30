#import <libkern/OSAtomic.h>
#import "IMUTLibDefaultTimeSource.h"
#import "IMUTLibConstants.h"
#import "IMUTLibFunctions.h"

NSUInteger IMUTLibDefaultTimeSourcePreference = 0;

@implementation IMUTLibDefaultTimeSource {
    NSDate *_startDate;
    double _referenceTime;
    OSSpinLock _lock;
}

#pragma mark IMUTLibTimeSource protocol

+ (NSNumber *)timeSourcePreference {
    return [NSNumber numberWithUnsignedLong:IMUTLibDefaultTimeSourcePreference];
}

- (NSString *)timeSourceInfo {
    return kDefault;
}

- (NSDate *)startDate {
    NSDate *startDate;

    OSSpinLockLock(&_lock);
    startDate = _startDate;
    OSSpinLockUnlock(&_lock);

    return startDate;
}

- (NSTimeInterval)intervalSinceClockStart {
    NSTimeInterval referenceTime = 0;

    OSSpinLockLock(&_lock);
    if(_startDate) {
        referenceTime = uptime() - _referenceTime;
    }
    OSSpinLockUnlock(&_lock);

    return referenceTime;
}

- (BOOL)startTicking {
    OSSpinLockLock(&_lock);
    _startDate = [NSDate date];
    _referenceTime = uptime();

    [self.timeSourceDelegate clockDidStartAtDate:_startDate];
    OSSpinLockUnlock(&_lock);

    return YES;
}

- (void)stopTicking {
    OSSpinLockLock(&_lock);
    _startDate = nil;

    [self.timeSourceDelegate clockDidStopAfterTimeInterval:[self intervalSinceClockStart]];

    _referenceTime = 0;
    OSSpinLockUnlock(&_lock);
}

@end
