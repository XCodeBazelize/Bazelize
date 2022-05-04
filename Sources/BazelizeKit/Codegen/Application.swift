//
//  File.swift
//
//
//  Created by Yume on 2022/4/29.
//

import Foundation
import XcodeProj

/// XcodeProj.PBXProductType.application
extension PBXNativeTarget {
    func generateApplicationCode(_ kit: Kit) -> String {
        
        //        - key: "IPHONEOS_DEPLOYMENT_TARGET"
        //        - value: "15.2"
        //                    let _build = path + target.name + "BUILD"
        let bundle_id = buildSettings.bundleID ?? ""
        let podDeps: String = kit.pod?[name] ?? ""
        let xcodeDeps = ""
        let xcodeSPMDeps = ""
        
        let code = """
        load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")
        load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
        
        swift_library(
            name = "_\(name)",
            module_name = "\(name)",
            srcs = [
        \(srcs)
            ],
            data = [
                "Base.lproj/Main.storyboard",
            ],
            deps = [
                # Cocoapod Deps
        \(podDeps)
        
                # XCode Deps
        \(xcodeDeps)
        
                # XCode SPM Deps
        \(xcodeSPMDeps)
            ],
        )
        
        ios_application(
            name = "\(name)",
            bundle_id = "\(bundle_id)",
            families = [
                "iphone",
                "ipad",
            ],
            minimum_os_version = "13.0",
            infoplists = [":Info.plist"],
            launch_storyboard = ":Base.lproj/LaunchScreen.storyboard",
            deps = [":_\(name)"],
            frameworks = [
            ],
        )
        """
        
        return code
    }
}
