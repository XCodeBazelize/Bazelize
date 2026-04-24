//
//  BuildSetting.swift
//
//
//  Created by Yume on 2022/4/29.
//

import AnyCodable
import Foundation
import XcodeProj

// MARK: - BuildSettings + Encodable

extension BuildSettings: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(AnyCodable(setting))
    }
}

// MARK: - BuildSettings

public struct BuildSettings {
    // MARK: Lifecycle

    init(_ project: Project, _ name: String, _ setting: [String: Any]) {
        self.project = project
        self.name = name
        self.setting = setting
    }

    init(_ project: Project, _ config: XCBuildConfiguration) {
        self.init(project, config.name, config.buildSettings)
    }

    // MARK: Public

    public unowned let project: Project

    /// Release / Debug / More...
    public let name: String
    public let setting: [String: Any]

    // MARK: Internal

    func merge(_ input: BuildSettings?) -> BuildSettings {
        guard let input = input else {
            return self
        }

        let newSetting = setting.merging(input.setting) { first, _ in
            first
        }

        return .init(project, name, newSetting)
    }

    internal subscript(key: String) -> String? {
        let value = setting[key]
        if let value = value as? String {
            return value
        }

        if let value = value as? BuildSetting {
            switch value {
            case .string(let string):
                return string
            case .array(let array):
                return array.joined(separator: " ")
            }
        }

        return nil
    }
}

// MARK: - SDK

public enum SDK: String, Encodable {
    case iOS = "iphoneos"
    case macOS = "macosx"
    case tvOS = "appletvos"
    case watchOS = "watchos"
    case driverKit = "driverkit"
    case auto
}

// MARK: - DeviceFamily

public enum DeviceFamily: String {
    case iphone = "1"
    case ipad = "2"
    case appletv = "3"
    case applewatch = "4"
    case homepod = "5"
    case mac = "6"

    public var code: String {
        switch self {
        case .iphone: return "iphone"
        case .ipad: return "ipad"
        case .appletv: return "appletv"
        case .applewatch: return "applewatch"
        case .homepod: return "homepod"
        case .mac: return "mac"
        }
    }

    public static func parse(_ code: String?) -> [DeviceFamily] {
        code?.split(separator: ",")
            .map(String.init)
            .compactMap(DeviceFamily.init(rawValue:)) ?? []
    }
}

extension BuildSettings {
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

    // SUPPORTED_PLATFORMS
    public var deviceFamily: [DeviceFamily] {
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



    public var swiftDefine: String? {
        self["OTHER_SWIFT_FLAGS"]
    }

    /// ios application uitest `Target Application`
    /// TEST_TARGET_NAME
    public var testTargetName: String? {
        self["TEST_TARGET_NAME"]
    }

    /// ios application unittest `Host Application`
    /// TEST_HOST
    public var testHost: String? {
        self["TEST_HOST"]
    }

    /// ios application unittest `Allow testing Host Application APIs`
    /// BUNDLE_LOADER
    public var bundleLoader: String? {
        self["BUNDLE_LOADER"]
    }

    /// CLANG_ENABLE_MODULES
    public var enableModules: Bool {
        self["CLANG_ENABLE_MODULES"] == "YES"
    }
}

// MARK: - PLIST Value -
extension BuildSettings {
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
