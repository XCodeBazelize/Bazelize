//
//  BuildSetting.swift
//
//
//  Created by Yume on 2022/4/29.
//

import AnyCodable
import Foundation
import PluginInterface
import XcodeProj

// MARK: - BuildSetting + XCodeBuildSetting

extension BuildSetting: XCodeBuildSetting { }

// MARK: - BuildSetting + Encodable

extension BuildSetting: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(AnyCodable(setting))
    }
}

// MARK: - BuildSetting

public struct BuildSetting {
    // MARK: Lifecycle


    init(_ name: String, _ setting: [String: Any]) {
        self.name = name
        self.setting = setting
    }

    init(_ config: XCBuildConfiguration) {
        self.init(config.name, config.buildSettings)
    }

    // MARK: Public

    /// Release / Debug / More...
    public let name: String
    public let setting: [String: Any]

    // MARK: Internal


    func merge(_ input: BuildSetting?) -> BuildSetting {
        guard let input = input else {
            return self
        }

        let newSetting = setting.merging(input.setting) { first, _ in
            first
        }

        return .init(name, newSetting)
    }

    // MARK: Private

    private static let PLIST_PREFIX = "INFOPLIST_KEY_"


    private subscript<T>(key: String) -> T? {
        setting[key] as? T
    }

    /// INFOPLIST_KEY_
    /// INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad
    private subscript<T>(plist key: String) -> T? {
        self["\(Self.PLIST_PREFIX)\(key)"]
    }
}

extension BuildSetting {
    /// com.xxx.ABCDEF
    public var bundleID: String? {
        self["PRODUCT_BUNDLE_IDENTIFIER"]
    }

    /// "37MR9UKGT3"
    public var team: String? {
        self["DEVELOPMENT_TEAM"]
    }

    /// "5.0"
    public var swiftVersion: String? {
        self["SWIFT_VERSION"]
    }

    public var deviceFamily: [String] {
        DeviceFamily.parse(self["TARGETED_DEVICE_FAMILY"])
    }

    /// SDKROOT
    public var sdk: SDK? {
        SDK(rawValue: self["SDKROOT"] ?? "")
    }

    public var iOS: String? {
        self["IPHONEOS_DEPLOYMENT_TARGET"]
    }

    public var macOS: String? {
        self["MACOSX_DEPLOYMENT_TARGET"]
    }

    public var tvOS: String? {
        self["TVOS_DEPLOYMENT_TARGET"]
    }

    public var watchOS: String? {
        self["WATCHOS_DEPLOYMENT_TARGET"]
    }

    public var driverKit: String? {
        self["DRIVERKIT_DEPLOYMENT_TARGET"]
    }
}

// MARK: - PLIST Key -
extension BuildSetting {
    public var plistKeys: [String] {
        setting.keys.filter {
            $0.hasPrefix(Self.PLIST_PREFIX)
        }
    }

    /// "YES"
    public var generateInfoPlist: Bool {
        let result: String? = self["GENERATE_INFOPLIST_FILE"]
        return result == "YES"
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
}

// MARK: - PLIST Value -
extension BuildSetting {
    /// CFBundleName $(PRODUCT_NAME)
    /// CFBundleIdentifier $(PRODUCT_BUNDLE_IDENTIFIER)
    /// CFBundleExecutable $(EXECUTABLE_NAME)
    /// CFBundlePackageType $(PRODUCT_BUNDLE_PACKAGE_TYPE)
    /// CFBundleDevelopmentRegion $(DEVELOPMENT_LANGUAGE)
    /// CFBundleVersion $(CURRENT_PROJECT_VERSION)
    /// CFBundleShortVersionString $(MARKETING_VERSION) 1.0
    //      - key: "MARKETING_VERSION"
    //      - value: "1.0"
    //      - key: "CURRENT_PROJECT_VERSION"
    //      - value: "1"

//    UIApplicationSceneManifest....UISceneDelegateClassName
//    $(PRODUCT_MODULE_NAME).SceneDelegate
//    PRODUCT_MODULE_NAME
//    $(PRODUCT_NAME:c99extidentifier)
//    PRODUCT_NAME
//    $(TARGET_NAME)
}

//    ▿ (2 elements)
//      - key: "LD_RUNPATH_SEARCH_PATHS"
//      ▿ value: 2 elements
//        - "$(inherited)"
//        - "@executable_path/Frameworks"
//    ▿ (2 elements)
//      - key: "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone"
//      - value: "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
//    ▿ (2 elements)
//      - key: "CODE_SIGN_STYLE"
//      - value: "Automatic"


//      - key: "ASSETCATALOG_COMPILER_APPICON_NAME"
//      - value: "AppIcon"
//      - key: "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME"
//      - value: "AccentColor"

//      - key: "SWIFT_EMIT_LOC_STRINGS"
//      - value: "YES"

// <key>UILaunchStoryboardName</key>
// <string>LaunchScreen</string>
// <key>UIMainStoryboardFile</key>
// <string>Main</string>
