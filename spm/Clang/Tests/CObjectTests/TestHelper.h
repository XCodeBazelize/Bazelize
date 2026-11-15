#import <Foundation/Foundation.h>

/// A header of the test target itself: it is an input of the compile, not
/// something another target can see.
static inline int CObjectTestsExpectedValue(void) {
    return 7;
}
