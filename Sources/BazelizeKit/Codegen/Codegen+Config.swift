//
//  Codegen+Config.swift
//
//
//  Created by Yume on 2022/8/5.
//

import Foundation
import PathKit
import PluginInterface
import RuleBuilder
import Util
import XCode

/// https://bazel.build/docs/configurable-attributes
extension Project {
    // MARK: Internal

    /// build:debug --//:mode=debug
    /// bazel build --config=debug [PACKAGE:RULE]
    internal func generateBazelRC(_ kit: Kit) throws {
        let configs = config?.keys.map { $0 } ?? []
        let bazelrc = kit.project.workspacePath + ".bazelrc"
        let code = configs.map { config in
            """
            build:\(config) --//:mode=\(config)
            """
        }.withNewLine
        Log.codeGenerate.info("Create `.bazelrc` at \(bazelrc.string, privacy: .public)")
        try bazelrc.write(code)
    }

    internal func generateBUILD(_ kit: Kit) throws {
        var builder = CodeBuilder()
        let code = generateCode(builder, kit)
        let build = kit.project.workspacePath + "BUILD"
        Log.codeGenerate.info("Create `BUILD` at \(build.string, privacy: .public)")
        try build.write(code)
    }

    // MARK: Private

    /// configs:
    ///     debug/release/...
    ///
    /// ```bazel
    /// select({
    ///     "//:deubg": "label1",
    ///     "//:release": "label2",
    ///     "//conditions:default": "label3",
    /// })
    /// ```
    ///
    /// ```shell
    /// bazel build target --//:mode=debug
    /// ```
    private func generateCode(_ builder: CodeBuilder, _: Kit) -> String {
        let configs = config?.keys.map { $0 } ?? []
        builder.load(.string_flag)
        builder.add(.string_flag) {
            "name" => "mode"
            "build_setting_default" => "normal"
        }

        for config in configs.sorted() {
            builder.add("config_setting") {
                "name" => "\(config)"
                "flag_values" => [":mode": "\(config)"]
            }
        }

        return builder.build()
    }
}
