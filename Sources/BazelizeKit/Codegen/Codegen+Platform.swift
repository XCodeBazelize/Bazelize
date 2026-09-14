import XCode2

extension Target {
    /// The platform the target builds for.
    ///
    /// `SDKROOT` is optional in a project file — Xcode falls back to the platform
    /// implied by the deployment target — so the rule choice cannot depend on the
    /// setting being present.
    var platformSDK: SDK? {
        if let sdk = prefer(\.platform.sdk), sdk != .auto {
            return sdk
        }

        /// `SDKROOT = auto` means the target is multiplatform: `SUPPORTED_PLATFORMS`
        /// narrows it down, and failing that an iPhone device family does.
        if let platform = prefer(\.platform.supportedPlatforms)?.first, platform != .auto {
            return platform
        }
        if prefer(\.platform.deviceFamily)?.contains(.iphone) == true {
            return .iOS
        }

        /// No usable `SDKROOT`: the deployment targets still say which platform the
        /// target builds for.
        if prefer(\.platform.iOS) != nil {
            return .iOS
        }
        if prefer(\.platform.macOS) != nil {
            return .macOS
        }
        if prefer(\.platform.tvOS) != nil {
            return .tvOS
        }
        if prefer(\.platform.watchOS) != nil {
            return .watchOS
        }

        return prefer(\.platform.sdk)
    }
}
