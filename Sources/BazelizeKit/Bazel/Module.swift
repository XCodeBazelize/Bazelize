//
//  Module.swift
//
//
//  Created by Yume on 2023/1/30.
//

import Foundation
import PathKit
import RuleBuilder

/// https://github.com/bazelbuild/bazel-central-registry
struct Module: BazelFile {
    let path: Path
    public let builder = CodeBuilder()

    init(_ root: Path) {
        path = root + "MODULE.bazel"

        setup()
    }

    var code: String {
        builder.build()
    }

    private func setup() {
        builder.add("module") {
            "name" => "example"
            "version" => "0.0.1"
        }
        builder.moduleDep(name: "bazel_skylib", version: "version")
    }
}
