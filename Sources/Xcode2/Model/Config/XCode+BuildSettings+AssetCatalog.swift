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

        /// `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS`
        ///
        /// Xcode 15+ generates `ImageResource`/`ColorResource` members from the
        /// catalogs and compiles them into the target.
        public var generatesSwiftSymbols: Bool {
            settings["ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS"] == "YES"
        }
    }
}
