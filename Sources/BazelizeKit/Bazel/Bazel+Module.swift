//
//  Module.swift
//
//
//  Created by Yume on 2023/1/30.
//

import Foundation
import PathKit
import Starlark

extension Bazel {
    /// https://github.com/bazelbuild/bazel-central-registry
    struct Module: BazelFile {
        let path: Path
        public let builder = CodeBuilder()
        private let skylib: Repo.BazelSkylib = .v1_9_0
        private let cc: Repo.RulesCC = .v0_2_18
        private let appleSupport: Repo.AppleSupport = .v2_5_4

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
            builder.bazel_dep(
                name: "bazel_skylib",
                version: skylib.rawValue)
            builder.bazel_dep(
                name: "apple_support",
                version: appleSupport.rawValue)
            builder.bazel_dep(
                name: "rules_cc",
                version: cc.rawValue)
        }
    }
}
