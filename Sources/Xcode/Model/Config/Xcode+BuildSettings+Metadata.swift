import Foundation

extension Xcode.BuildSettings {
    public var metadata: Metadata {
        .init(settings: self)
    }

    public struct Metadata {
        fileprivate let settings: Xcode.BuildSettings

        public var bundleID: String? {
            settings["PRODUCT_BUNDLE_IDENTIFIER"]
        }

        public var moduleName: String? {
            settings["PRODUCT_MODULE_NAME"]
        }

        public var productName: String? {
            settings["PRODUCT_NAME"]
        }

        public var developmentTeam: String? {
            settings["DEVELOPMENT_TEAM"]
        }

        public var codeSignStyle: String? {
            settings["CODE_SIGN_STYLE"]
        }

        public var codeSignIdentity: String? {
            settings["CODE_SIGN_IDENTITY"]
        }

        public var codeSignEntitlements: String? {
            settings["CODE_SIGN_ENTITLEMENTS"]
        }
    }
}
