import Foundation

/// The same generated rule is compiled for every Apple platform. Each one gets
/// only the settings and dependencies its configuration selects.
#if !APPLE_PLATFORM
#error("A setting conditional on Apple platforms must apply")
#endif

#if targetEnvironment(macCatalyst)
#if !MACCATALYST_PLATFORM
#error("A setting conditional on Mac Catalyst must apply")
#endif
#if IOS_PLATFORM
#error("A setting conditional on iOS must not apply to Mac Catalyst")
#endif
import MacCatalystOnly
#elseif os(macOS)
#if !MACOS_PLATFORM
#error("A setting conditional on macOS must apply to a macOS build")
#endif
#if IOS_PLATFORM || MACCATALYST_PLATFORM
#error("An iOS-family setting must not apply to a macOS build")
#endif
#elseif os(iOS)
#if !IOS_PLATFORM
#error("A setting conditional on iOS must apply to an iOS build")
#endif
#if MACOS_PLATFORM || MACCATALYST_PLATFORM
#error("A macOS-family setting must not apply to an iOS build")
#endif
import IOSOnly
#elseif os(tvOS)
#if !TVOS_PLATFORM
#error("A setting conditional on tvOS must apply to a tvOS build")
#endif
import TVOSOnly
#elseif os(watchOS)
#if !WATCHOS_PLATFORM
#error("A setting conditional on watchOS must apply to a watchOS build")
#endif
import WatchOSOnly
#elseif os(visionOS)
#if !VISIONOS_PLATFORM
#error("A setting conditional on visionOS must apply to a visionOS build")
#endif
import VisionOSOnly
#else
#error("The fixture must compile for a supported Apple platform")
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
        #if targetEnvironment(macCatalyst)
        if #available(macCatalyst 16.0, *) { true } else { false }
        #elseif os(macOS)
        if #available(macOS 13.0, *) { true } else { false }
        #elseif os(iOS)
        if #available(iOS 16.0, *) { true } else { false }
        #elseif os(tvOS)
        if #available(tvOS 16.0, *) { true } else { false }
        #elseif os(watchOS)
        if #available(watchOS 9.0, *) { true } else { false }
        #elseif os(visionOS)
        if #available(visionOS 1.0, *) { true } else { false }
        #endif
    }

    /// Reaches the dependency selected only for the active platform.
    public static var selectedDependency: String {
        #if targetEnvironment(macCatalyst)
        MacCatalystOnly.value
        #elseif os(macOS)
        "macOS"
        #elseif os(iOS)
        IOSOnly.value
        #elseif os(tvOS)
        TVOSOnly.value
        #elseif os(watchOS)
        WatchOSOnly.value
        #elseif os(visionOS)
        VisionOSOnly.value
        #endif
    }
}
