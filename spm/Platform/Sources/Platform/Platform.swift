import Foundation

/// The same generated rule is compiled for more than one platform. Each one
/// gets only the settings and dependencies its configuration selects.
#if !APPLE_PLATFORM
#error("A setting conditional on either Apple platform must apply")
#endif

#if os(macOS)
#if !MACOS_PLATFORM
#error("A setting conditional on macOS must apply to a macOS build")
#endif
#if IOS_PLATFORM
#error("A setting conditional on iOS must not apply to a macOS build")
#endif
#elseif os(iOS)
#if MACOS_PLATFORM
#error("A setting conditional on macOS must not apply to an iOS build")
#endif
#if !IOS_PLATFORM
#error("A setting conditional on iOS must apply to an iOS build")
#endif
import IOSOnly
#endif

#if LINUX_PLATFORM
#error("A setting conditional on Linux must not apply to an Apple build")
#endif

#if WINDOWS_PLATFORM
#error("A setting conditional on Windows must not apply to an Apple build")
#endif

// MARK: - Platform

public enum Platform {
    /// What the package says it needs, which is what the rules have to compile
    /// it for: a build older than this would not have the API.
    public static var deploymentTargetIsDeclared: Bool {
        if #available(macOS 13.0, *) { true } else { false }
    }
}
