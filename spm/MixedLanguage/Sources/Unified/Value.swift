import Foundation

// MARK: - SwiftAPI

/// Swift half of the module: it calls the C half directly, with no import
/// beyond the module's own.
public enum SwiftAPI {
    public static let value = 42

    /// `unified_c_value()`, from C.
    public static var cValue: Int { Int(unified_c_value()) }

    public static var cFlag: Bool { unified_c_flag() == 1 }

    public static var cIsC11: Bool { unified_c_is_c11() == 1 }

    public static var cHeaderFlag: Bool { UNIFIED_HEADER_FLAG == 1 }

    public static var swiftFlag: Bool {
        #if UNIFIED_SWIFT_FLAG
        true
        #else
        false
        #endif
    }

    /// Swift -> Objective-C -> Swift -> C.
    public static func roundTrip(_ seed: Int) -> Int {
        unified_round_trip(seed)
    }
}

// MARK: - SwiftBridge

/// What the Objective-C half calls through `Unified-Swift.h`.
@objc(UnifiedSwiftBridge)
public final class SwiftBridge: NSObject {
    @objc
    public static func step(_ seed: Int) -> Int {
        seed * 2 + SwiftAPI.value
    }
}
