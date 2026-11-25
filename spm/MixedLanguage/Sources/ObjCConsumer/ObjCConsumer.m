#import "ObjCConsumer.h"
@import Unified;

/// One import reaches both halves of the mixed module: its C function and the
/// Swift class it exposes to Objective-C.
NSInteger objc_consumer_total(NSInteger seed) {
    return [UnifiedSwiftBridge step:seed] + unified_c_value();
}
