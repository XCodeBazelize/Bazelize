import Foundation

extension Xcode.BuildSettings {
    // MARK: Info.plist

    public var plist: Plist {
        .init(settings: self)
    }

    public var generatedPlist: GeneratedPlist {
        .init(settings: self)
    }

    /// The `INFOPLIST_KEY_*` settings Bazelize knows the value type of. The raw
    /// value is the `Info.plist` key the setting writes.
    ///
    /// Declared in the order `GeneratedPlist.entries` writes them.
    enum InfoPlistKey: String, CaseIterable {
        case cfBundleDisplayName = "CFBundleDisplayName"
        case uiApplicationSupportsIndirectInputEvents = "UIApplicationSupportsIndirectInputEvents"
        case uiLaunchStoryboardName = "UILaunchStoryboardName"
        case uiMainStoryboardFile = "UIMainStoryboardFile"
        case uiSupportedInterfaceOrientations = "UISupportedInterfaceOrientations"

        /// What every one of these settings starts with.
        static let prefix = "INFOPLIST_KEY_"

        /// The build setting: `INFOPLIST_KEY_CFBundleDisplayName`.
        var setting: String {
            "\(Self.prefix)\(rawValue)"
        }

        fileprivate var value: InfoPlistValue {
            switch self {
            case .cfBundleDisplayName, .uiLaunchStoryboardName, .uiMainStoryboardFile:
                .string
            case .uiSupportedInterfaceOrientations:
                .stringArray
            case .uiApplicationSupportsIndirectInputEvents:
                .bool
            }
        }
    }

    subscript(infoPlist key: InfoPlistKey) -> String? {
        self[key.setting]
    }

    public struct Plist {
        fileprivate let settings: Xcode.BuildSettings

        /// "ABCDEF/Info.plist"
        public var infoPlist: String? {
            settings[.infoPlistFile]
        }

        /// "LaunchScreen"
        public var launch: String? {
            settings[infoPlist: .uiLaunchStoryboardName]
        }

        /// "Main"
        public var storyboard: String? {
            settings[infoPlist: .uiMainStoryboardFile]
        }

        /// Every `INFOPLIST_KEY_*` the target states, known or not:
        /// `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad`.
        public var keys: [String] {
            settings.keys.filter { key in
                key.hasPrefix(InfoPlistKey.prefix)
            }
            .sorted()
        }
    }

    public struct GeneratedPlist {
        fileprivate let settings: Xcode.BuildSettings

        /// "YES"
        public var enabled: Bool {
            settings.bool(.generateInfoPlistFile) == true
        }

        /// CFBundleVersion - CURRENT_PROJECT_VERSION
        ///
        /// Default Info.plist value:
        /// CFBundleVersion -> $(CURRENT_PROJECT_VERSION)
        public var currentProjectVersion: String? {
            settings[.currentProjectVersion]
        }

        /// CFBundleShortVersionString - MARKETING_VERSION
        ///
        /// Default Info.plist value:
        /// CFBundleShortVersionString -> $(MARKETING_VERSION)
        public var marketingVersion: String? {
            settings[.marketingVersion]
        }

        /// Default Info.plist value:
        /// CFBundleName -> $(PRODUCT_NAME)
        /// CFBundleIdentifier -> $(PRODUCT_BUNDLE_IDENTIFIER)
        /// CFBundleExecutable -> $(EXECUTABLE_NAME)
        /// CFBundlePackageType -> $(PRODUCT_BUNDLE_PACKAGE_TYPE)
        /// CFBundleDevelopmentRegion -> $(DEVELOPMENT_LANGUAGE)
        public var defaultInfoPlistKeyNotes: [String] {
            [
                "CFBundleName -> \(Key.productName.reference)",
                "CFBundleIdentifier -> \(Key.productBundleIdentifier.reference)",
                "CFBundleExecutable -> \(Key.executableName.reference)",
                "CFBundlePackageType -> \(Key.productBundlePackageType.reference)",
                "CFBundleDevelopmentRegion -> \(Key.developmentLanguage.reference)",
                "CFBundleVersion -> \(Key.currentProjectVersion.reference)",
                "CFBundleShortVersionString -> \(Key.marketingVersion.reference)",
            ]
        }

        /// GENERATED_INFOPLIST_FILE
        ///
        /// Render the `INFOPLIST_KEY_*` settings `InfoPlistKey` knows into plist
        /// XML fragments so generated Info.plist files preserve common Xcode
        /// build-setting customizations.
        public var entries: [String] {
            guard enabled else { return [] }

            return InfoPlistKey.allCases.flatMap { key -> [String] in
                guard let value = settings[infoPlist: key] else { return [] }

                let element = switch key.value {
                case .string:
                    plistString(value)
                case .stringArray:
                    plistStringArray(value)
                case .bool:
                    plistBool(value)
                }
                return ["<key>\(key.rawValue)</key>", element]
            }
        }

        private func plistBool(_ value: String) -> String {
            value == "YES" ? "<true/>" : "<false/>"
        }

        private func plistString(_ value: String) -> String {
            "<string>\(value)</string>"
        }

        private func plistStringArray(_ value: String) -> String {
            let strings = value
                .split(separator: " ")
                .map(String.init)
                .map(plistString)
                .map { "    \($0)" }
                .joined(separator: "\n")

            return """
            <array>
            \(strings)
            </array>
            """
        }
    }
}

// MARK: - InfoPlistValue

/// How an `InfoPlistKey`'s setting is written into the `Info.plist`.
private enum InfoPlistValue {
    case string
    case stringArray
    case bool
}
