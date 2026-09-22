import Foundation

/// `swiftLanguageMode(.v5)`: the target compiles as Swift 5 whatever the
/// manifest's tools version is.
#if swift(>=6.0)
#error("The target must compile in Swift 5 language mode")
#endif

/// `define`.
#if !MANIFEST_DEFINE
#error("The manifest define must reach Swift sources")
#endif

/// `unsafeFlags`.
#if !UNSAFE_DEFINE
#error("Unsafe Swift flags must reach Swift sources")
#endif

/// `enableUpcomingFeature`.
#if !hasFeature(MemberImportVisibility)
#error("The upcoming feature must be enabled")
#endif

/// `enableExperimentalFeature`: `@_extern` below is the feature's syntax, and
/// only parses when the compiler was told to enable it.

/// `strictMemorySafety`.
#if !hasFeature(StrictMemorySafety)
#error("Strict memory safety must be enabled")
#endif

/// The symbol the linker's `-alias` flags point at.
@_cdecl("swiftsettings_probe")
public func swiftSettingsProbe() -> Int32 {
    42
}

/// The alias itself: the linker made it, or this does not link.
@_extern(c, "swiftsettings_probe_alias")
func swiftSettingsProbeAlias() -> Int32

/// `crc32`, from the library the manifest links.
@_extern(c, "crc32")
func zlibCRC32(_ crc: UInt, _ buffer: UnsafePointer<UInt8>?, _ length: UInt32) -> UInt

/// `SecCopyErrorMessageString`, from the framework the manifest links.
@_extern(c, "SecCopyErrorMessageString")
func secCopyErrorMessageString(_ status: Int32, _ reserved: UnsafeMutableRawPointer?) -> OpaquePointer?

public enum SettingProbe {
    /// Isolated to the main actor by `defaultIsolation`, not by an attribute:
    /// calling it from anywhere else has to hop, and `assumeIsolated` traps if
    /// it did not.
    public static func isolation() -> Bool {
        MainActor.assumeIsolated { true }
    }

    /// The linked library's answer for `abc`.
    public static func checksum() -> UInt {
        let bytes: [UInt8] = Array("abc".utf8)
        return unsafe zlibCRC32(0, bytes, UInt32(bytes.count))
    }

    /// The linked framework's message for "no error".
    public static func frameworkMessage() -> String? {
        guard let message = unsafe secCopyErrorMessageString(0, nil) else { return nil }
        return unsafe Unmanaged<CFString>.fromOpaque(UnsafeRawPointer(message))
            .takeRetainedValue() as String
    }

    /// What the aliased symbol answers, which is what the original does.
    public static func aliased() -> Int32 {
        swiftSettingsProbeAlias()
    }
}
