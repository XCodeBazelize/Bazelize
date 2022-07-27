//
//  XCodeProject.swift
//  
//
//  Created by Yume on 2022/7/25.
//

import Foundation

public protocol XCodeProject {

    var path: String { get }

    var root: String { get }
    
    #warning("todo spm")
//    var other: Int { get }

    var targets: [XCodeTarget] { get }
}

public protocol XCodeTarget {

    /// Target Name
    var name: String { get }
    
    /// Release/Debug/More ...
    var configs: [String] { get }
    
    var config: [String: XCodeBuildSetting] { get }

    /// swift
    /// m
    /// mm
    /// ...
    var srcs: String { get }
    /// var srcs_swift: String { get }
    /// var hdr
    
    var resources: String { get }

    /// use for `frameworks`
    var importFrameworks: String { get }

    /// use for `frameworks`
    var frameworks: String { get }

    /// use for `xxx_library.deps`
    ///
    var frameworks_library: String { get }

    /// use for `sdk_frameworks`
    var sdkFrameworks: String { get }
}

public protocol XCodeBuildSetting {

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
