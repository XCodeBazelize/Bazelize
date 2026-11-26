#import "DownstreamBridge.h"
@import Unified;

NSInteger downstream_total(NSInteger seed) {
    return [UnifiedSwiftBridge step:seed] + unified_c_value();
}
