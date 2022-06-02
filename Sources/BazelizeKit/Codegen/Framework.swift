//
//  Framework.swift
//  
//
//  Created by Yume on 2022/4/29.
//

import Foundation
import XcodeProj

//XcodeProj.PBXProductType.framework
extension PBXNativeTarget {
    func generateFrameworkCode(_ kit: Kit) -> String {
        let bundle_id = buildSettings.bundleID ?? ""
        let podDeps: String = kit.pod?[name] ?? ""
        let xcodeDeps = ""
        let xcodeSPMDeps = spm_deps.joined(separator: "\n")
        
        let code = """
        load("@build_bazel_rules_apple//apple:ios.bzl", "ios_framework")
        load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
        
        swift_library(
            name = "_\(name)",
            module_name = "\(name)",
            srcs = [
        \(srcs)
            ],
            deps = [
                # Cocoapod Deps
        \(podDeps)

                # XCode SPM Deps
        \(xcodeSPMDeps)
            ],
        )
        
        ios_framework(
            name = "\(name)",
            bundle_id = "\(bundle_id)",
            families = [
                "iphone",
                "ipad",
            ],
            minimum_os_version = "13.0",
            infoplists = [":Info.plist"],
            deps = [":_\(name)"],
            frameworks = [
                # XCode Target Deps
            \(xcodeDeps)
            ],
        )
        """
        
        return code
    }
}
