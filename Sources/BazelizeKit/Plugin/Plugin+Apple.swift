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
    let dep: BazelDep.Apple = .latest

    override func module(_ builder: CodeBuilder) {
        builder.bazel_dep(
            name: "rules_apple",
            version: dep.rawValue,
            repo_name: "build_bazel_rules_apple")
    }
}
