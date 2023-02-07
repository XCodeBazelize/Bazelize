//
//  PluginApple.swift
//
//
//  Created by Yume on 2023/2/3.
//

import Foundation

// MARK: - PluginApple

/// https://github.com/bazelbuild/rules_apple
final class PluginApple: PluginBuiltin {
    let repo: Repo.Apple = .v2_0_0

    override func module(_ builder: CodeBuilder) {
        builder.moduleDep(
            name: "rules_apple",
            version: repo.rawValue,
            repo_name: "build_bazel_rules_apple")
    }

    override func workspace(_ builder: CodeBuilder) {
        let version = repo.version
        builder.custom("""
        # rules_apple
        http_archive(
            name = "build_bazel_rules_apple",
            sha256 = "\(repo.sha256)",
            url = "https://github.com/bazelbuild/rules_apple/releases/download/\(version)/rules_apple.\(version).tar.gz",
        )

        load(
            "@build_bazel_rules_apple//apple:repositories.bzl",
            "apple_rules_dependencies",
        )

        apple_rules_dependencies()

        load(
            "@build_bazel_apple_support//lib:repositories.bzl",
            "apple_support_dependencies",
        )

        apple_support_dependencies()
        """)
    }
}
