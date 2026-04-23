//
//  PluginXCodeProj.swift
//
//
//  Created by Yume on 2023/2/3.
//

import Foundation
import XCode
import XcodeProj

// MARK: - PluginXCodeProj

/// https://github.com/MobileNativeFoundation/rules_xcodeproj
final class PluginXCodeProj: PluginBuiltin {
    let repo: Repo.XCodeProj = .v3_6_0
    override func module(_ builder: CodeBuilder) {
        builder.bazelDep(
            name: "rules_xcodeproj",
            version: repo.rawValue
        )
    }
    
    // TODO:
    /// top target
    /// custom project_name
    /// not support swift_library -> static library
    /// target_environments `device` need provision_profile
    override func build(_ builder: CodeBuilder) {
        let targets = kit.project.targets
        let other = targets
            .map(\.name)
            .sorted()
            .map { name in
                """
                "//\(name):\(name)",
                """
            }.withNewLine.indent(2)
        
        builder.load(
            module: "@rules_xcodeproj//xcodeproj:defs.bzl",
            symbols: ["top_level_target", "xcodeproj"]
        )
        
        builder.custom("""
        # Xcode
        xcodeproj(
            name = "xcodeproj",
            # Custom Project Name
            project_name = "App",
            tags = ["manual"],
            top_level_targets = [
                # main target, maybe some `ios_application`
                top_level_target(":App", target_environments = ["device", "simulator"]),
                # all other target
        \(other)
            ],
        )
        """)
    }
}
