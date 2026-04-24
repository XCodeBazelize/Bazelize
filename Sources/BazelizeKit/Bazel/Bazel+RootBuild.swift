//
//  Build.swift
//
//
//  Created by Yume on 2022/12/8.
//

import BazelRules
import Foundation
import PathKit
import RuleBuilder
import XCode

extension Bazel {
    /// /BUILD
    struct RootBuild: BazelFile {
        let path: Path
        public let builder = CodeBuilder()

        init(_ root: Path) {
            path = root + "BUILD"
        }

        var code: String {
            builder.build()
        }

        /// Generates repo-root build configuration selectors.
        ///
        /// This emits a `string_flag(name = "mode", ...)` plus one
        /// `config_setting(...)` per Xcode configuration name, so package BUILD
        /// files can switch values with `select(...)`.
        ///
        /// Example generated at the repo root:
        ///
        /// ```bazel
        /// string_flag(
        ///     name = "mode",
        ///     build_setting_default = "Debug",
        ///     values = ["Debug", "Release"],
        /// )
        ///
        /// config_setting(
        ///     name = "Debug",
        ///     flag_values = {
        ///         ":mode": "Debug",
        ///     },
        /// )
        /// ```
        ///
        /// Example usage from another rule:
        ///
        /// ```bazel
        /// defines = select({
        ///     "//:Debug": ["DEBUG"],
        ///     "//:Release": ["RELEASE"],
        ///     "//conditions:default": [],
        /// })
        /// ```
        ///
        /// Example command line:
        ///
        /// ```shell
        /// bazel build //Example:Example --//:mode=Debug
        /// ```
        func setup(config: [String : BuildSettings]?) {
            guard let config = config else { return }
            let configs = config.keys.sorted()
            guard let defaultConfig = configs.first else { return }

            builder.load(.string_flag)
            builder.call(
                Rules.Config.Call.string_flag(
                    name: "mode",
                    build_setting_default: defaultConfig,
                    values: configs))

            for config in configs {
                builder.call(
                    Rules.Builtin.Call.config_setting(
                        name: config,
                        flag_values: [":mode": config]))
            }
        }

        /// ~~export files not in~~
        /// [Bazel Package](https://bazel.build/concepts/build-ref)
        ///
        /// don't need to export files
        func exportUncategorizedFiles(_: Kit) {
//            let all = kit.project.all
//                .filter(\.isFile)
//                .compactMap(\.label)
//                .filter { label in
//                    label.hasPrefix("//:")
//                }
//                .map { label in
//                    // TODO: remove //:
//                """
//                "\(label.delete(prefix: "//:"))"
//                """
//                }
//
//            guard all.count != 0 else { return }
//
//            builder.custom("")
//            builder.custom("""
//            # export files not in [Bazel Package](https://bazel.build/concepts/build-ref)
//            exports_files([
//            \(all.map(\.withComma).withNewLine.indent(1))
//            ])
//            """)
        }
    }
}
