extension Xcode.BuildSettings {
    /// How Xcode spells a language feature it can turn on, turn off, or
    /// diagnose without enforcing: `SWIFT_UPCOMING_FEATURE_*` and
    /// `SWIFT_STRICT_MEMORY_SAFETY`. A plain boolean setting takes the first
    /// two.
    enum FeatureState: String {
        case yes = "YES"
        case no = "NO"
        case migrate = "MIGRATE"
    }

    /// `SWIFT_STRICT_CONCURRENCY`.
    enum StrictConcurrency: String {
        case minimal
        case targeted
        case complete
    }

    /// `MACH_O_TYPE`: what the linker makes of a target's objects.
    public enum MachOType: String, Sendable {
        case executable = "mh_execute"
        case dynamicLibrary = "mh_dylib"
        case bundle = "mh_bundle"
        case staticLibrary = "staticlib"
        case relocatableObject = "mh_object"
    }
}
