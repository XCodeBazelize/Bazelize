#import "Unified.h"
#import "Unified-Swift.h"

NSInteger unified_round_trip(NSInteger seed) {
    return [UnifiedSwiftBridge step:seed] + unified_c_value();
}
