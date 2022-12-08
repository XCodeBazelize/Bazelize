//
//  File.swift
//
//
//  Created by Yume on 2022/7/1.
//

import Foundation

// MARK: - DeviceFamily

/// "1,2"
/// 1: iphone
/// 2: ipad
/// 3: appletv?
/// 4: applewatch?
/// 5: homepod?
/// 6: mac?
internal enum DeviceFamily: String {
    case iphone = "1"
    case ipad = "2"
    case appletv = "3"
    case applewatch = "4"
    case homepod = "5"
    case mac = "6"

    // MARK: Internal

    internal var code: String {
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
    internal static func parse(_ code: String?) -> [String] {
        code?.split(separator: ",")
            .map(String.init)
            .compactMap(DeviceFamily.init(rawValue:))
            .map(\.code) ?? []
    }
}


// MARK: - SupportedPlatform

/// SUPPORTED_PLATFORMS
enum SupportedPlatform: String {
    case iphonesimulator
    case iphoneos
    case driverkit
    case macosx
    case appletvsimulator
    case appletvos
    case watchsimulator
    case watchos
}


/// catalyst
/// SUPPORTS_MACCATALYST

/// design for ipad
/// SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD
