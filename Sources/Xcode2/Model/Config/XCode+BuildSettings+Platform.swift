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
