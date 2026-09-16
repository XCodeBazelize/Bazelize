import Foundation

// MARK: - SDK

public enum SDK: String, Hashable {
    case iOS = "iphoneos"
    case macOS = "macosx"
    case tvOS = "appletvos"
    case watchOS = "watchos"
    case driverKit = "driverkit"
    case auto
}

extension XCode.BuildSettings {
    public var platform: Platform {
        .init(settings: self)
    }

    public struct Platform {
        fileprivate let settings: XCode.BuildSettings

        public var sdk: SDK? {
            SDK(rawValue: settings["SDKROOT"] ?? "")
        }

        /// `SUPPORTED_PLATFORMS`, which decides the platform when `SDKROOT = auto`.
        public var supportedPlatforms: [SDK] {
            (settings["SUPPORTED_PLATFORMS"] ?? "")
                .split(separator: " ")
                .compactMap { SDK(rawValue: String($0)) }
        }

        public var iOS: String? {
            settings["IPHONEOS_DEPLOYMENT_TARGET"]
        }

        public var macOS: String? {
            settings["MACOSX_DEPLOYMENT_TARGET"]
        }

        public var tvOS: String? {
            settings["TVOS_DEPLOYMENT_TARGET"]
        }

        public var watchOS: String? {
            settings["WATCHOS_DEPLOYMENT_TARGET"]
        }

        public var driverKit: String? {
            settings["DRIVERKIT_DEPLOYMENT_TARGET"]
        }

        public var deploymentTargets: [String: String] {
            [
                "iOS": iOS,
                "macOS": macOS,
                "tvOS": tvOS,
                "watchOS": watchOS,
                "driverKit": driverKit,
            ].compactMapValues { $0 }
        }

        /// The platform the settings build for.
        ///
        /// `SDKROOT` is optional in a project file, and `auto` means the target is
        /// multiplatform: `SUPPORTED_PLATFORMS` narrows it down, then the device
        /// family, then whichever deployment target is set.
        public var resolvedSDK: SDK? {
            if let sdk, sdk != .auto {
                return sdk
            }
            if let platform = supportedPlatforms.first(where: { $0 != .auto }) {
                return platform
            }
            if deviceFamily.contains(.iphone) {
                return .iOS
            }
            if iOS != nil {
                return .iOS
            }
            if macOS != nil {
                return .macOS
            }
            if tvOS != nil {
                return .tvOS
            }
            if watchOS != nil {
                return .watchOS
            }

            return sdk
        }

        public var deviceFamily: [XCode.DeviceFamily] {
            XCode.DeviceFamily.parse(settings["TARGETED_DEVICE_FAMILY"])
        }

        public var appleFamiliesLiteral: String? {
            let families = deviceFamily.map(\.code)
            guard !families.isEmpty else { return nil }
            return "[" + families.map { #""\#($0)""# }.joined(separator: ", ") + "]"
        }
    }
}
