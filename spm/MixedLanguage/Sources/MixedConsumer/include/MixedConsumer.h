#import <Foundation/Foundation.h>

/// The Objective-C half of a mixed target that depends on `Unified`:
/// `unified_round_trip(seed)` plus the Swift bridge's `step(seed)`. For 1 that
/// is 85 + 44 = 129.
NSInteger mixed_consumer_objc(NSInteger seed);
