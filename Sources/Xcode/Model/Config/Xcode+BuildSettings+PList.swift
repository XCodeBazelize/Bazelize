import Foundation

private let plistPrefix = "INFOPLIST_KEY_"

extension Xcode.BuildSettings {
    // MARK: Info.plist

    public var plist: Plist {
        .init(settings: self)
    }

    public var generatedPlist: GeneratedPlist {
        .init(settings: self)
    }

    public struct Plist {
        fileprivate let settings: Xcode.BuildSettings

        /// "ABCDEF/Info.plist"
        public var infoPlist: String? {
            settings["INFOPLIST_FILE"]
        }

        /// "LaunchScreen"
        public var launch: String? {
            plistValue("UILaunchStoryboardName")
        }

        /// "Main"
        public var storyboard: String? {
            plistValue("UIMainStoryboardFile")
        }

        /// INFOPLIST_KEY_
        /// INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad
        public var keys: [String] {
            settings.keys.filter { key in
                key.hasPrefix(plistPrefix)
            }
            .sorted()
        }

        private func plistValue(_ key: String) -> String? {
            settings["\(plistPrefix)\(key)"]
        }
    }

    public struct GeneratedPlist {
        fileprivate let settings: Xcode.BuildSettings

        /// "YES"
        public var enabled: Bool {
            settings["GENERATE_INFOPLIST_FILE"] == "YES"
        }

        /// CFBundleVersion - CURRENT_PROJECT_VERSION
        ///
        /// Default Info.plist value:
        /// CFBundleVersion -> $(CURRENT_PROJECT_VERSION)
        public var currentProjectVersion: String? {
            settings["CURRENT_PROJECT_VERSION"]
        }

        /// CFBundleShortVersionString - MARKETING_VERSION
        ///
        /// Default Info.plist value:
        /// CFBundleShortVersionString -> $(MARKETING_VERSION)
        public var marketingVersion: String? {
            settings["MARKETING_VERSION"]
        }

        /// Default Info.plist value:
        /// CFBundleName -> $(PRODUCT_NAME)
        /// CFBundleIdentifier -> $(PRODUCT_BUNDLE_IDENTIFIER)
        /// CFBundleExecutable -> $(EXECUTABLE_NAME)
        /// CFBundlePackageType -> $(PRODUCT_BUNDLE_PACKAGE_TYPE)
        /// CFBundleDevelopmentRegion -> $(DEVELOPMENT_LANGUAGE)
        public var defaultInfoPlistKeyNotes: [String] {
            [
                "CFBundleName -> $(PRODUCT_NAME)",
                "CFBundleIdentifier -> $(PRODUCT_BUNDLE_IDENTIFIER)",
                "CFBundleExecutable -> $(EXECUTABLE_NAME)",
                "CFBundlePackageType -> $(PRODUCT_BUNDLE_PACKAGE_TYPE)",
                "CFBundleDevelopmentRegion -> $(DEVELOPMENT_LANGUAGE)",
                "CFBundleVersion -> $(CURRENT_PROJECT_VERSION)",
                "CFBundleShortVersionString -> $(MARKETING_VERSION)",
            ]
        }

        /// GENERATED_INFOPLIST_FILE
        ///
        /// Render a minimal subset of INFOPLIST_KEY_* settings into plist XML
        /// fragments so generated Info.plist files preserve common Xcode
        /// build-setting customizations.
        public var entries: [String] {
            guard enabled else { return [] }

            return settings.plist.keys.sorted().flatMap { key -> [String] in
                guard let value = settings[key] else { return [] }

                switch plistDecision(for: key) {
                case .string:
                    return [plistKey(key), plistString(value)]
                case .stringArray:
                    return [plistKey(key), plistStringArray(value)]
                case .bool:
                    return [plistKey(key), plistBool(value)]
                case .unknown:
                    return []
                }
            }
        }

        private func plistDecision(for key: String) -> PlistDecision {
            switch key {
            case "INFOPLIST_KEY_UIMainStoryboardFile",
                 "INFOPLIST_KEY_UILaunchStoryboardName":
                return .string
            case "INFOPLIST_KEY_UISupportedInterfaceOrientations":
                return .stringArray
            case "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents":
                return .bool
            default:
                return .unknown
            }
        }

        private func plistKey(_ key: String) -> String {
            let newKey = key.delete(prefix: plistPrefix) ?? key
            return "<key>\(newKey)</key>"
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

// MARK: - PlistDecision

private enum PlistDecision {
    case string
    case stringArray
    case bool
    case unknown
}
