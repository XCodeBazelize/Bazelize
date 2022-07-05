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
        precondition(self.bundleID != nil, "bundle id")
        precondition(self.version != nil, "min version")
        
        let depsXcode = ""
        
        let deviceFamily = self.deviceFamily?.joined(separator: "\n") ?? ""
        
//        self.infoPlist
        
        var builder = Build.Builder()
        builder.load(.ios_framework)
        builder.custom(generateSwiftLibrary(kit))
        
        builder.custom("""
        ios_framework(
            name = "\(name)",
            bundle_id = "\(self.bundleID!)",
            families = [
        \(deviceFamily.indent(2))
            ],
            minimum_os_version = "\(self.version!)",
            infoplists = [":Info.plist"],
            deps = [":_\(name)"],
            frameworks = [
                # XCode Target Deps
            \(depsXcode)
            ],
            visibility = ["//visibility:public"],
        )
        """)
                
        return builder.build()
    }
}
