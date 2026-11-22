#import <Foundation/Foundation.h>
#import "Probe.h"

int main(void) {
    @autoreleasepool {
        int unrelatedValue = 0;
#ifdef FILE_VALUE
        unrelatedValue = FILE_VALUE;
#endif
        if (!__has_feature(objc_arc) || !legacyIsManualReferenceCounting()
            || flaggedValue() != 73 || unrelatedValue != 0) {
            fprintf(stderr, "Per-file ARC or macro flags were lost or leaked\n");
            return 1;
        }
        puts("ARC default, MRC override, isolated FILE_VALUE=73");
        return 0;
    }
}
