import Foundation

extension XCode.BuildSettings {
    public var assetCatalog: AssetCatalog {
        .init(settings: self)
    }

    public struct AssetCatalog {
        fileprivate let settings: XCode.BuildSettings

        public var appIconName: String? {
            settings["ASSETCATALOG_COMPILER_APPICON_NAME"]
        }

        public var accentColorName: String? {
            settings["ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME"]
        }
    }
}
