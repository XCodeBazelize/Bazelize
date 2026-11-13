/// A back-port of the shape packages ship constantly: available from the
/// version that lacked the real thing, and obsolete once the platform has it.
///
/// The package declares macOS 13, so this type is reachable. Compiled against a
/// newer floor — the SDK's own default, say — using it is an error, which is
/// how a build that lost the package's deployment target fails here rather than
/// somewhere downstream.
@available(macOS, introduced: 10.15, obsoleted: 14, message: "Use the platform's own")
public struct BackportedShim {
    public static let value = 13
}

public enum FloorProbe {
    /// The call is the assertion: it only compiles below macOS 14.
    public static func shimValue() -> Int {
        BackportedShim.value
    }
}
