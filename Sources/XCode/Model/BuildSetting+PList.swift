//
//  BuildSetting+PList.swift
//
//
//  Created by Yume on 2022/8/9.
//

import Foundation
import PathKit
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
    // MARK: Public

    public var defaultPlist: [String] {
        let content: String?
        if let plistPath = infoPlist {
            let path: Path = project.workspacePath + plistPath
            content = try? path.read()
        } else {
            content = nil
        }

        let xmls = DefaultPlist.allCases.filter { (key: DefaultPlist) in
            self[key.rawValue] == nil ||
                !(content?.contains(key.rawValue) ?? false)
        }.map(\.xml).sorted()
        return fillShortVersion(fillVersion(xmls))
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

        // MARK: Fileprivate

        fileprivate var xml: String {
            """
            <key>\(rawValue)</key>
            <string>\(value)</string>
            """
        }

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
    }

    // MARK: Private

    /// CFBundleVersion - CURRENT_PROJECT_VERSION
    private var CURRENT_PROJECT_VERSION: String? {
        self[#function]
    }

    /// CFBundleShortVersionString - MARKETING_VERSION
    private var MARKETING_VERSION: String? {
        self[#function]
    }

    private func fillVersion(_ xmls: [String]) -> [String] {
        guard let version = CURRENT_PROJECT_VERSION else { return xmls }
        return xmls.map { xml in
            xml.replacingOccurrences(of: "$(CURRENT_PROJECT_VERSION)", with: version)
        }
    }

    private func fillShortVersion(_ xmls: [String]) -> [String] {
        guard let version = MARKETING_VERSION else { return xmls }
        return xmls.map { xml in
            xml.replacingOccurrences(of: "$(MARKETING_VERSION)", with: version)
        }
    }
}

extension BuildSetting {
    // MARK: Public

    public var plist: [String] {
        guard generateInfoPlist else { return [] }

        let xmls = plistKeys.sorted().flatMap { key -> [String?] in
            let newKey = Self.key(key)

            guard let value = self[key] else {
                return [Self.comment(newKey), nil]
            }

            switch Decision(key) {
            case .string:
                return [newKey, Self.string(value)]
            case .stringArray:
                return [newKey, Self.stringArray(value)]
            case .bool:
                return [newKey, Self.bool(value)]
            case .unknown:
                return [Self.comment(newKey), Self.comment(value)]
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
        value == "YES" ? "<true/>" : "<false/>"
    }

    static func string(_ value: String) -> String {
        "<string>\(value)</string>"
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
        "<!--<key>\(value)</key>-->"
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
