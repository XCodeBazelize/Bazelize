import Foundation

extension Xcode.BuildSettings {
    public var stringCatalog: StringCatalog {
        .init(settings: self)
    }

    public struct StringCatalog {
        fileprivate let settings: Xcode.BuildSettings

        /// `STRING_CATALOG_GENERATE_SYMBOLS`
        ///
        /// Xcode 26+ runs `xcstringstool generate-symbols` over every `.xcstrings`
        /// table of the target and compiles the result into it, which is where
        /// `LocalizedStringResource.ok` and friends come from.
        public var generatesSymbols: Bool {
            settings["STRING_CATALOG_GENERATE_SYMBOLS"] == "YES"
        }
    }
}
