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

    var deviceFamily: [String] { get }

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
}

// MARK: - SDK

public enum SDK: String, Encodable {
    case iOS = "iphoneos"
    case macOS = "macosx"
    case tvOS = "appletvos"
    case watchOS = "watchos"
    case DriverKit = "driverkit"
}
