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
import XCode

/// https://bazel.build/docs/configurable-attributes
extension Project {
    /// build:debug --//:mode=debug
    /// bazel build --config=debug [PACKAGE:RULE]
    public func generateBazelRC(_ kit: Kit) throws {
        let configs = self.config?.keys.map { $0 } ?? []
        let bazelrc = kit.project.workspacePath + ".bazelrc"
        let code = configs.map { config in
            return """
            build:\(config) --//:mode=\(config)
            """
        }.withNewLine
        print("Create \(bazelrc.string)")
        try bazelrc.write(code)
    }
    
    public func generateBUILD(_ kit: Kit) throws {
        let code = generateCode(kit)
        let build = kit.project.workspacePath + "BUILD"
        print("Create \(build.string)")
        try build.write(code)
    }
    
    /// configs:
    ///     debug/release/...
    ///
    /// ```bazel
    /// select({
    ///     ":deubg": "label1",
    ///     ":release": "label2",
    ///     "//conditions:default": "label3",
    /// })
    /// ```
    ///
    /// ```shell
    /// bazel build target --//:mode=debug
    /// ```
    private func generateCode(_ kit: Kit) -> String {
        let configs = self.config?.keys.map { $0 } ?? []
        var builder = Build.Builder()
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
