import Foundation

extension Xcode.BuildSettings {
    public var metadata: Metadata {
        .init(settings: self)
    }

    public struct Metadata {
        fileprivate let settings: Xcode.BuildSettings

        public var bundleID: String? {
            settings[.productBundleIdentifier]
        }

        public var moduleName: String? {
            settings[.productModuleName]
        }

        public var productName: String? {
            settings[.productName]
        }

        public var developmentTeam: String? {
            settings[.developmentTeam]
        }

        public var codeSignStyle: String? {
            settings[.codeSignStyle]
        }

        public var codeSignIdentity: String? {
            settings[.codeSignIdentity]
        }

        public var codeSignEntitlements: String? {
            settings[.codeSignEntitlements]
        }
    }
}
