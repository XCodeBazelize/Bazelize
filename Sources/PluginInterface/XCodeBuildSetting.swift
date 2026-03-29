//
//  XCodeBuildSetting.swift
//
//
//  Created by Yume on 2022/7/29.
//

import Foundation

// MARK: - XCodeBuildSetting

public protocol XCodeBuildSetting {
    var name: String { get }

    var setting: [String: Any] { get }

    var bundleID: String? { get }

    var team: String? { get }

    /// "5.0"
    var swiftVersion: String? { get }

    var deviceFamily: [DeviceFamily] { get }

    /// SDKROOT
    var sdk: SDK? { get }

    // MARK: - OS version -
    var iOS: String? { get }

    var macOS: String? { get }

    var tvOS: String? { get }

    var watchOS: String? { get }

    var driverKit: String? { get }

    // MARK: - plist -
    /// "YES"
    var generateInfoPlist: Bool { get }

    var plist: [String] { get }

    /// plist gen keys
    var plistKeys: [String] { get }

    /// "ABCDEF/Info.plist"
    var infoPlist: String? { get }

    var defaultPlist: [String] { get }

    /// "LaunchScreen"
    var launch: String? { get }

    /// "Main"
    var storyboard: String? { get }

    var swiftDefine: String? { get }

    /// ios application uitest `Target Application`
    /// TEST_TARGET_NAME
    var testTargetName: String? { get }

    /// ios application unittest `Host Application`
    /// TEST_HOST
    var testHost: String? { get }

    /// ios application unittest `Allow testing Host Application APIs`
    /// BUNDLE_LOADER
    var bundleLoader: String? { get }

    /// CLANG_ENABLE_MODULES
    var enableModules: Bool { get }
}

// MARK: - SDK

public enum SDK: String, Encodable {
    case iOS = "iphoneos"
    case macOS = "macosx"
    case tvOS = "appletvos"
    case watchOS = "watchos"
    case driverKit = "driverkit"
    case auto = "auto"
}


// MARK: - DeviceFamily

/// "1,2"
/// 1: iphone
/// 2: ipad
/// 3: appletv?
/// 4: applewatch?
/// 5: homepod?
/// 6: mac?
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


    /// `1,2` -> [`"iphone"` `"ipad"`]
    public static func parse(_ code: String?) -> [DeviceFamily] {
        code?.split(separator: ",")
            .map(String.init)
            .compactMap(DeviceFamily.init(rawValue:)) ?? []
    }
}
