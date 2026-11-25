#import <Foundation/Foundation.h>

/// An Objective-C target that depends on `Unified`: the Swift bridge's
/// `step(seed)` plus the C `unified_c_value()`. For 1 that is 44 + 41 = 85.
NSInteger objc_consumer_total(NSInteger seed);
