//
//  Codegen+Framework.swift
//
//
//  Created by Yume on 2022/4/29.
//

import Foundation
import XCode

extension Target {
    func generateFrameworkCode(_ kit: Kit) -> String {
        precondition(setting.bundleID != nil, "bundle id")
//        precondition(setting.version != nil, "min version")
        
        let depsXcode = ""
        
        let deviceFamily = setting.deviceFamily.withNewLine
        
//        self.infoPlist
        
        var builder = Build.Builder()
        builder.load(.ios_framework)
        builder.custom(generateSwiftLibrary(kit))
        
        builder.custom("""
        ios_framework(
            name = "\(name)",
            bundle_id = "\(setting.bundleID!)",
            families = [
        \(deviceFamily.indent(2))
            ],
            # minimum_os_version = "(setting.version!)",
            # (self.infoPlist ?? "")
            infoplists = [
                # ":Info.plist",
                (self.plistLabel)
            ],
            deps = [":\(name)_library"],
            frameworks = [
                # XCode Target Deps
        \(depsXcode.indent(2))
            ],
            visibility = ["//visibility:public"],
        )
        """)
                
        return builder.build()
    }
}
