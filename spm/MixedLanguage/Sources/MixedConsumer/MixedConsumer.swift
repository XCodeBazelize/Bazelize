import Unified

/// The Swift half of a mixed target that depends on `Unified`.
public enum MixedConsumerAPI {
    /// `SwiftAPI.value` plus the C `unified_c_value()`: 42 + 41 = 83.
    public static var total: Int { SwiftAPI.value + Int(unified_c_value()) }

    /// Its own Objective-C half, reached through its own module.
    public static func objc(_ seed: Int) -> Int { mixed_consumer_objc(seed) }
}
