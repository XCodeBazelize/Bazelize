//
//  PluginXCodeProj.swift
//
//
//  Created by Yume on 2023/2/3.
//

import Foundation

// MARK: - PluginXCodeProj

/// https://github.com/buildbuddy-io/rules_xcodeproj
final class PluginXCodeProj: PluginBuiltin {
    let repo: Repo.XCodeProj = .v0_12_3
    override func module(_ builder: CodeBuilder) {
        builder.custom("""
        bazel_dep(name = "rules_xcodeproj", version = "\(repo.rawValue)")
        """)
    }

    override func workspace(_ builder: CodeBuilder) {
        builder.custom("""
        # rules_xcodeproj
        http_archive(
            name = "com_github_buildbuddy_io_rules_xcodeproj",
            sha256 = "\(repo.sha256)",
            url = "https://github.com/buildbuddy-io/rules_xcodeproj/releases/download/\(repo.rawValue)/release.tar.gz",
        )

        load(
            "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:repositories.bzl",
            "xcodeproj_rules_dependencies",
        )

        xcodeproj_rules_dependencies()
        """)
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

        builder.load("""
        load(
            "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:defs.bzl",
            "top_level_target",
            "xcodeproj",
        )
        """)

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
