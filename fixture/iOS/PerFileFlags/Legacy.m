#import <Foundation/Foundation.h>
#import "Probe.h"

static int deallocations;
@interface PerFileCounter : NSObject
@end
@implementation PerFileCounter
- (void)dealloc {
    ++deallocations;
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}
@end

int legacyIsManualReferenceCounting(void) {
#if __has_feature(objc_arc)
    return 0;
#else
    deallocations = 0;
    PerFileCounter *counter = [PerFileCounter new];
    [counter release];
    return deallocations == 1;
#endif
}
