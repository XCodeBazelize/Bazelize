//
//  BuildSetting+PList.swift
//
//
//  Created by Yume on 2022/8/9.
//

import Foundation
import Util

// <key>UISceneDelegateClassName</key>
// <string>$(PRODUCT_NAME).SceneDelegate</string>
// <true/>

// load("//build-system/bazel-utils:plist_fragment.bzl",
//    "plist_fragment",
// )

// plist_fragment(
//    name = "BuildNumberInfoPlist",
//    extension = "plist",
//    template =
//    """
//    <key>CFBundleVersion</key>
//    <string>{buildNumber}</string>
//    """
// )

private let PLIST_PREFIX = "INFOPLIST_KEY_"
// MARK: - PLIST Key -
// TODO: https://github.com/XCodeBazelize/Bazelize/issues/5
extension BuildSetting {
    // MARK: Public

    /// "YES"
    public var generateInfoPlist: Bool {
        let result: String? = self["GENERATE_INFOPLIST_FILE"]
        return result == "YES"
    }

    public var plistKeys: [String] {
        setting.keys.filter {
            $0.hasPrefix(PLIST_PREFIX)
        }
    }

    /// "ABCDEF/Info.plist"
    public var infoPlist: String? {
        self["INFOPLIST_FILE"]
    }

    /// "LaunchScreen"
    public var launch: String? {
        self[plist: "UILaunchStoryboardName"]
    }

    /// "Main"
    public var storyboard: String? {
        self[plist: "UIMainStoryboardFile"]
    }

    // MARK: Private


    /// INFOPLIST_KEY_
    /// INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad
    private subscript(plist key: String) -> String? {
        self["\(PLIST_PREFIX)\(key)"]
    }
}

extension BuildSetting {
    // MARK: Internal


    func defaultPlist() -> [String] {
        DefaultPlist.allCases.filter { (key: DefaultPlist) in
            self[key.rawValue] != nil
        }.map(\.xml).sorted()
    }

    // MARK: Fileprivate

    fileprivate enum DefaultPlist: String, CaseIterable {
        case CFBundleName
        case CFBundleIdentifier
        case CFBundleVersion
        case CFBundleExecutable
        case CFBundlePackageType
        case CFBundleDevelopmentRegion
        case CFBundleShortVersionString

        // MARK: Private


        private var value: String {
            switch self {
            case .CFBundleName: return "$(PRODUCT_NAME)"
            case .CFBundleIdentifier: return "$(PRODUCT_BUNDLE_IDENTIFIER)"
            case .CFBundleVersion: return "$(CURRENT_PROJECT_VERSION)"
            case .CFBundleExecutable: return "$(EXECUTABLE_NAME)"
            case .CFBundlePackageType: return "$(PRODUCT_BUNDLE_PACKAGE_TYPE)"
            case .CFBundleDevelopmentRegion: return "$(DEVELOPMENT_LANGUAGE)"
            case .CFBundleShortVersionString: return "$(MARKETING_VERSION)"
            }
        }

        fileprivate var xml: String {
            return """
            <key>\(rawValue)</key>
            <string>\(value)</string>
            """
        }
    }
}

extension BuildSetting {
    // MARK: Internal

    func plist() -> [String] {
        guard generateInfoPlist else { return [] }

        let xmls = plistKeys.sorted().flatMap { key -> [String?] in
            let key = Self.key(key)

            guard let value = self[key] else {
                return [Self.comment(key), nil]
            }

            switch Decision(key) {
            case .string:
                return [key, Self.string(value)]
            case .stringArray:
                return [key, Self.stringArray(value)]
            case .bool:
                return [key, Self.bool(value)]
            case .unknown:
                return [Self.comment(key), Self.comment(value)]
            }
        }.compactMap { $0 }

        return xmls
    }

    // MARK: Fileprivate


    fileprivate enum Decision {
        case string
        case stringArray
        case bool
        case unknown
        fileprivate init(_ key: String) {
            switch key {
            case "INFOPLIST_KEY_UIMainStoryboardFile": fallthrough
            case "INFOPLIST_KEY_UILaunchStoryboardName":
                self = .string
            case "INFOPLIST_KEY_UISupportedInterfaceOrientations": fallthrough
            case "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone": fallthrough
            case "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad":
                self = .stringArray
            case "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents":
                self = .bool
            default:
                self = .unknown
            }
        }
    }
}

extension BuildSetting {
    // MARK: Internal


    static func bool(_ value: String) -> String {
        return value == "YES" ? "<true/>" : "<false/>"
    }

    static func string(_ value: String) -> String {
        return "<string>\(value)</string>"
    }

    static func stringArray(_ value: String) -> String {
        let strings = value
            .split(separator: " ")
            .map(String.init)
            .compactMap(Self.string)
            .withNewLine
            .indent(1)

        return [
            "<array>",
            strings,
            "</array>",
        ].withNewLine
    }

    static func comment(_ value: String) -> String {
        return "<!--<key>\(value)</key>-->"
    }

    // MARK: Private

    /// transform
    ///     `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad`
    /// to
    ///     `UISupportedInterfaceOrientations~iPad`
    private static func key(_ key: String) -> String {
        let newKey = key
            .delete(prefix: PLIST_PREFIX)
            .replacingOccurrences(of: "_", with: "~")

        return "<key>\(newKey)</key>"
    }
}
