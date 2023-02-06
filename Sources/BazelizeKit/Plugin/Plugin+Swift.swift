//
//  PluginSwift.swift
//
//
//  Created by Yume on 2023/2/3.
//

import Foundation

// MARK: - PluginSwift

/// https://github.com/bazelbuild/rules_swift
final class PluginSwift: PluginBuiltin {
    let repo: Repo.Swift = .v1_5_0

    override func module(_ builder: CodeBuilder) {
        builder.custom("""
        bazel_dep(name = "rules_swift", version = "\(repo.rawValue)", repo_name = "build_bazel_rules_swift")
        """)
    }

    override func workspace(_ builder: CodeBuilder) {
        builder.custom("""
        # rules_swift
        http_archive(
            name = "build_bazel_rules_swift",
            sha256 = "\(repo.sha256)",
            url = "https://github.com/bazelbuild/rules_swift/releases/download/\(repo.rawValue)/rules_swift.\(
                repo
                    .rawValue).tar.gz",
        )

        load(
            "@build_bazel_rules_swift//swift:repositories.bzl",
            "swift_rules_dependencies",
        )

        swift_rules_dependencies()

        load(
            "@build_bazel_rules_swift//swift:extras.bzl",
            "swift_rules_extra_dependencies",
        )

        swift_rules_extra_dependencies()
        """)
    }
}
