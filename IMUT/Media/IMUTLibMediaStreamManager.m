#import "IMUTLibMediaStreamManager.h"

@implementation IMUTLibMediaStreamManager {
    NSMutableDictionary *_writers;
}

SINGLETON

- (instancetype)init {
    if (self = [super init]) {
        _writers = [NSMutableDictionary dictionary];
    }

    return self;
}

- (IMUTLibMediaStreamWriter *)writerWithBasename:(NSString *)basename {
    IMUTLibMediaStreamWriter *writer = [_writers objectForKey:basename];
    if (writer) {
        return writer;
    }

    writer = [IMUTLibMediaStreamWriter writerWithBasename:basename];
    [_writers setObject:writer forKey:basename];

    return writer;
}

@end
