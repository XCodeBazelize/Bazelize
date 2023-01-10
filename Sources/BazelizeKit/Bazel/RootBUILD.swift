//
//  Build.swift
//
//
//  Created by Yume on 2022/12/8.
//

import Foundation
import PathKit
import PluginInterface
import RuleBuilder

/// /BUILD
struct Build: BazelFile {
    // MARK: Lifecycle

    init(_ root: Path) {
        path = root + "BUILD"
    }

    // MARK: Internal

    let path: Path
    private(set) var code = ""

    mutating
    func build() {
        code = builder.build()
    }

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
    mutating
    func setup(config: [String : XCodeBuildSetting]?) {
        guard let config = config else { return }
        let configs = config.keys.map { $0 }

        builder.load(.string_flag)
        builder.add(.string_flag) {
            "name" => "mode"
            "build_setting_default" => "Debug"
        }

        for config in configs.sorted() {
            builder.add("config_setting") {
                "name" => "\(config)"
                "flag_values" => [":mode": "\(config)"]
            }
        }
    }

    /// export files not in [Bazel Package](https://bazel.build/concepts/build-ref)
    mutating
    func exportUncategorizedFiles(_ kit: Kit) {
        let all = kit.project.all
            .filter(\.isFile)
            .compactMap(\.label)
            .filter { label in
                label.hasPrefix("//:")
            }
            .map { label in
                // TODO: remove //:
                """
                "\(label.delete(prefix: "//:"))"
                """
            }

        guard all.count != 0 else { return }

        builder.custom("")
        builder.custom("""
        # export files not in [Bazel Package](https://bazel.build/concepts/build-ref)
        exports_files([
        \(all.map(\.withComma).withNewLine.indent(1))
        ])
        """)
    }

    // MARK: Private

    private var builder = Build.Builder()
}
