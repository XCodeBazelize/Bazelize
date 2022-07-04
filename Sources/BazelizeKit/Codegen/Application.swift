//
//  Application.swift
//
//
//  Created by Yume on 2022/4/29.
//

import Foundation
import XCode

extension SDK {
    var load: String {
        switch self {
        case .iOS: return RulesApple.IOS.ios_application.code
        /// RulesApple.Mac.macos_command_line_application
        case .macOS: return RulesApple.Mac.macos_application.code
        case .tvOS: return RulesApple.TV.tvos_application.code
        case .watchOS: return RulesApple.Watch.watchos_application.code
        case .DriverKit: return ""
        }
    }
    
    var application: String {
        switch self {
        case .iOS: return RulesApple.IOS.ios_application.rawValue
        /// RulesApple.Mac.macos_command_line_application
        case .macOS: return RulesApple.Mac.macos_application.rawValue
        case .tvOS: return RulesApple.TV.tvos_application.rawValue
        case .watchOS: return RulesApple.Watch.watchos_application.rawValue
        case .DriverKit: return ""
        }
    }
}

extension Target {
    func generateApplicationCode(_ kit: Kit) -> String {
        precondition(self.sdk?.load != nil, "sdk")
        precondition(self.sdk?.application != nil, "sdk")
        
        precondition(self.bundleID != nil, "bundle id")
        precondition(self.version != nil, "min version")
        
        let depsXcode = ""
        
        let deviceFamily = self.deviceFamily?.joined(separator: "\n") ?? ""
        
//        infoPlist
        
        var builder = Build.Builder()
        builder.custom(self.sdk!.load)
        builder.custom(generateSwiftLibrary(kit))
        
//        let application = self.sdk?.load
        builder.custom("\(self.sdk!.application)(")
//        ios_application(
        builder.custom("""
            name = "\(name)",
            bundle_id = "\(self.bundleID!)",
            families = [
        \(deviceFamily.indent(2))
            ],
            minimum_os_version = "\(self.version!)",
            infoplists = [":Info.plist"],
            launch_storyboard = ":Base.lproj/LaunchScreen.storyboard",
            deps = [":_\(name)"],
            frameworks = [
                # XCode Target Deps
        \(depsXcode)
            ],
        )
        """)

        return builder.build()
    }
}
