//
//  PluginLinker.swift
//
//
//  Created by Yume on 2023/2/3.
//

import Foundation

/// deps
/// "@rules_apple_linker//:zld"
/// "@rules_apple_linker//:lld"

/// https://github.com/keith/rules_apple_linker
class PluginLinker: PluginBuiltin {
    override func module(_ builder: CodeBuilder) {
        builder.custom(
            """
            bazel_dep(name = "rules_apple_linker", version = "0.3.0")
            """)
    }

    override func workspace(_ builder: CodeBuilder) {
        builder.custom("""
        load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

        http_archive(
            name = "rules_apple_linker",
            sha256 = "a8aecd86d9c63677a8f1a3849c52c05d4aed1d1d9c209db2904f53f8973731d4",
            strip_prefix = "rules_apple_linker-0.3.0",
            url = "https://github.com/keith/rules_apple_linker/archive/refs/tags/0.3.0.tar.gz",
        )

        load("@rules_apple_linker//:deps.bzl", "rules_apple_linker_deps")

        rules_apple_linker_deps()
        """)
    }
}
