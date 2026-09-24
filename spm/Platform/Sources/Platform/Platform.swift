import Foundation

/// Kept: macOS is a platform an Apple toolchain builds, and the one this is
/// compiled for.
#if !APPLE_PLATFORM
#error("A setting conditional on an Apple platform must apply")
#endif

#if !MACOS_PLATFORM
#error("A setting conditional on macOS must apply to a macOS build")
#endif

/// Dropped while the rules are written: nothing generated here is ever
/// compiled for Linux or Windows, so a setting behind one is not a `select` —
/// it is not there at all.
#if LINUX_PLATFORM
#error("A setting conditional on Linux must not apply")
#endif

#if WINDOWS_PLATFORM
#error("A setting conditional on Windows must not apply")
#endif

public enum Platform {
    /// What the package says it needs, which is what the rules have to compile
    /// it for: a build older than this would not have the API.
    public static var deploymentTargetIsDeclared: Bool {
        if #available(macOS 13.0, *) { true } else { false }
    }
}
