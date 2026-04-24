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
    let repo: Repo.Swift = .v3_4_1

    override func module(_ builder: CodeBuilder) {
        builder.bazel_dep(
            name: "rules_swift",
            version: repo.rawValue,
            repo_name: "build_bazel_rules_swift"
        )
    }
}
