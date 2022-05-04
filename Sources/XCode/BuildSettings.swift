//
//  File.swift
//
//
//  Created by Yume on 2022/4/29.
//

import Foundation
import XcodeProj

public struct BuildSettings {
    let setting: [String: Any]
    init(_ target: PBXNativeTarget, _ configName: String = "Release") {
        let config = target.buildConfigurationList?.buildConfigurations.first { config in
            return config.name == configName
        }
        
        self.setting = config?.buildSettings ?? [:]
    }
    
    private subscript<T>(key: String) -> T? {
        return setting[key] as? T
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
    
    /// "1,2"
    public var deviceFamily: String? {
        self["TARGETED_DEVICE_FAMILY"]
    }
    
    //      - key: "MARKETING_VERSION"
    //      - value: "1.0"
    //      - key: "CURRENT_PROJECT_VERSION"
    //      - value: "1"
    
    /// "LaunchScreen"
    public var launch: String? {
        self["INFOPLIST_KEY_UILaunchStoryboardName"]
    }
    
    /// "Main"
    public var storyboard: String? {
        self["INFOPLIST_KEY_UIMainStoryboardFile"]
    }
    
    /// "YES"
    public var generateInfoPlist: Bool {
        let result: String? = self["GENERATE_INFOPLIST_FILE"]
        return result == "YES"
    }
    /// "ABCDEF/Info.plist"
    public var infoPlist: String? {
        return self["INFOPLIST_FILE"]
    }
    
    //      - key: "ASSETCATALOG_COMPILER_APPICON_NAME"
    //      - value: "AppIcon"
    //      - key: "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME"
    //      - value: "AccentColor"
    
    //      - key: "SWIFT_EMIT_LOC_STRINGS"
    //      - value: "YES"
}
//    ▿ (2 elements)
//      - key: "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad"
//      - value: "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
//    ▿ (2 elements)
//      - key: "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents"
//      - value: "YES"
//    ▿ (2 elements)
//      - key: "PRODUCT_NAME"
//      - value: "$(TARGET_NAME)"
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
