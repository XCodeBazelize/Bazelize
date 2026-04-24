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
    let repo: Repo.Apple = .v4_3_3

    override func module(_ builder: CodeBuilder) {
        builder.bazel_dep(
            name: "rules_apple",
            version: repo.rawValue,
            repo_name: "build_bazel_rules_apple")
    }
}
