//
//  PluginArchive.swift
//
//
//  Created by Yume on 2023/1/31.
//

import Foundation

// MARK: - PluginGitRepository

final class PluginGitRepository: PluginBuiltin {
    override var name: String { "Bazel Git Repository" }
    override func module(_ builder: CodeBuilder) {
        builder.custom("""
        git_repository = use_repo_rule("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
        """)
    }
}
