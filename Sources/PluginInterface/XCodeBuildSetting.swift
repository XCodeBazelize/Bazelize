//
//  XCodeBuildSetting.swift
//  
//
//  Created by Yume on 2022/7/29.
//

import Foundation

public protocol XCodeBuildSetting {
    
    var name: String { get }
    
    var setting: [String: Any] { get }

    /// com.xxx.ABCDEF
    var bundleID: String? { get }

    /// "37MR9XXXXX"
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
    
    /// plist gen keys
    var plistKeys: [String] { get }

    /// "ABCDEF/Info.plist"
    var infoPlist: String? { get }

    /// "LaunchScreen"
    var launch: String? { get }

    /// "Main"
    var storyboard: String? { get }
}

public enum SDK: String, Encodable {
    case iOS = "iphoneos"
    case macOS = "macosx"
    case tvOS = "appletvos"
    case watchOS = "watchos"
    case DriverKit = "driverkit"
}
