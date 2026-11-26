import DownstreamBridge
import Unified

/// A Swift target in another package, and an Objective-C one beside it, both
/// reach the C and the Swift interface of `Unified`.
func check(_ condition: Bool, _ message: String) {
    guard condition else {
        fatalError("FAIL: \(message)")
    }
}

check(SwiftAPI.value == 42, "Swift interface from another package")
check(unified_c_value() == 41, "C interface from another package")
check(downstream_total(1) == 85, "Objective-C in another package uses both interfaces")

print("downstream ok")
