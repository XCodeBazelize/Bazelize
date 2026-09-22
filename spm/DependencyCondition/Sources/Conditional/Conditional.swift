import Always

/// The dependency behind `.when(platforms: [.linux])`: this is a macOS build,
/// so that package is not part of it and its module cannot be imported. A
/// build that pulled it in anyway would fail right here.
#if !os(Linux) && canImport(LinuxOnly)
#error("A dependency conditional on Linux must not be linked into a macOS build")
#endif
#if canImport(Extras)
import Extras
#endif

public enum Conditional {
    public static let always = Always.value

    /// What the package behind a trait provides, and `nil` when the trait is
    /// off — the dependency is then not part of the build at all.
    public static var extras: Int? {
        #if canImport(Extras)
        return Extras.value
        #else
        return nil
        #endif
    }
}
