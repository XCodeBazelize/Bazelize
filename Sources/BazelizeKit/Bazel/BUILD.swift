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

struct Build: BazelFile {
    // MARK: Lifecycle

    init(_ root: Path, _ target: String? = nil) {
        if let target = target {
            path = root + target + "BUILD"
        } else {
            path = root + "BUILD"
        }
    }

    // MARK: Internal

    let path: Path
    private(set) var code = ""


    mutating
    func setup(_ build: (inout Builder) -> Void) {
        var builder = Build.Builder()
        build(&builder)
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

        setup { builder in
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
        }
    }
}
