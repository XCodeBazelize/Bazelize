import Foundation

public extension XCode.BuildSettings {
    var platform: Platform {
        .init(settings: self)
    }

    struct Platform {
        fileprivate let settings: XCode.BuildSettings

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
