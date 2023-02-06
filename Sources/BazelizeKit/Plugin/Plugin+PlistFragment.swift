//
//  PluginPlistFragment.swift
//
//
//  Created by Yume on 2023/2/3.
//

import Foundation

// MARK: - PluginPlistFragment

/// https://github.com/imWildCat/MinimalBazelFrameworkDemo
final class PluginPlistFragment: PluginBuiltin {
    override func workspace(_ builder: CodeBuilder) {
        builder.custom("""
        load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
        git_repository(
            name = "Plist",
            commit = "259ca0a5d77833728c18fa6365285559ce8cc0bf",
            remote = "https://github.com/imWildCat/MinimalBazelFrameworkDemo",
        )
        """)
    }
}
