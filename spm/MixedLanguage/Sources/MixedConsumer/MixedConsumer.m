#import "MixedConsumer.h"
@import Unified;

NSInteger mixed_consumer_objc(NSInteger seed) {
    return unified_round_trip(seed) + [UnifiedSwiftBridge step:seed];
}
