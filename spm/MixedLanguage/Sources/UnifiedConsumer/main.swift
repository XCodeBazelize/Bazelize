import MixedConsumer
import ObjCConsumer
import Unified

/// One import reaches both languages: the Swift API and the C functions.
func check(_ condition: Bool, _ message: String) {
    guard condition else {
        fatalError("FAIL: \(message)")
    }
}

check(SwiftAPI.value == 42, "Swift value")
check(unified_c_value() == 41, "C value")
check(SwiftAPI.cValue == 41, "Swift calls C")
check(SwiftAPI.cHeaderFlag, "C settings reach Swift's underlying module")
check(unified_c_flag() == 1 && SwiftAPI.cFlag, "C define")
check(unified_c_is_c11() == 1 && SwiftAPI.cIsC11, "C language standard")
check(SwiftAPI.swiftFlag, "Swift define")
check(unified_round_trip(5) == 93, "C calls Swift: direct")
check(SwiftAPI.roundTrip(5) == 93, "Swift -> ObjC -> Swift -> C")
check(objc_consumer_total(1) == 85, "Objective-C dependent uses Unified's C and Swift")
check(MixedConsumerAPI.total == 83, "mixed dependent's Swift uses Unified's C and Swift")
check(MixedConsumerAPI.objc(1) == 129, "mixed dependent's Objective-C uses Unified's C and Swift")

print("unified ok")
