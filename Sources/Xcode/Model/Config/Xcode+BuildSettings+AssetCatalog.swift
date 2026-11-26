import Foundation

extension Xcode.BuildSettings {
    public var assetCatalog: AssetCatalog {
        .init(settings: self)
    }

    public struct AssetCatalog {
        fileprivate let settings: Xcode.BuildSettings

        public var appIconName: String? {
            settings[.appIconName]
        }

        public var accentColorName: String? {
            settings[.globalAccentColorName]
        }

        /// `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS`
        ///
        /// Xcode 15+ generates `ImageResource`/`ColorResource` members from the
        /// catalogs and compiles them into the target.
        public var generatesSwiftSymbols: Bool {
            settings.bool(.generateSwiftAssetSymbolExtensions) == true
        }

        /// `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES`: the extra icons the
        /// user can switch to. `nil` when the target does not state the setting;
        /// an explicitly empty value is `[]`.
        ///
        /// Entries are whitespace-separated and may be quoted, because an icon
        /// name can hold a space (`"Dark Mode"`).
        public var alternateAppIconNames: [String]? {
            guard let value = settings[.alternateAppIconNames] else { return nil }
            return Self.tokens(value)
        }

        /// `ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS`: `true` for `YES`,
        /// `false` for `NO`, `nil` when the target does not say.
        public var includeAllAppIconAssets: Bool? {
            settings.bool(.includeAllAppIconAssets)
        }

        /// Whitespace-separated, quote-aware, without Xcode's `$(inherited)` marker.
        private static func tokens(_ value: String) -> [String] {
            var result: [String] = []
            var current = ""
            var quote: Character?
            var started = false
            for character in value {
                if let open = quote {
                    if character == open { quote = nil } else { current.append(character) }
                } else if character == "\"" || character == "'" {
                    quote = character
                    started = true
                } else if character.isWhitespace {
                    if started { result.append(current) }
                    current = ""
                    started = false
                } else {
                    current.append(character)
                    started = true
                }
            }
            if started { result.append(current) }
            return result.filter { !$0.isEmpty && $0 != "$(inherited)" }
        }
    }
}
