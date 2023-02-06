//
//  PluginArchive.swift
//
//
//  Created by Yume on 2023/1/31.
//

import Foundation

// MARK: - PluginArchive

final class PluginArchive: PluginBuiltin {
    override var name: String { "Bazel HTTP Archive" }
    override func workspace(_ builder: CodeBuilder) {
        builder.custom("""
        load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
        """)
    }
}
