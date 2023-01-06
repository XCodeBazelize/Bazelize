//
//  BazelRC.swift
//
//
//  Created by Yume on 2022/12/8.
//

import Foundation
import PathKit
import PluginInterface

/// [config](https://bazel.build/docs/configurable-attributes)
/// [.bazelrc](https://bazel.build/run/bazelrc)
///
///
/// TODO:
/// TIP: `import %workspace%/config.bazelrc` in `.bazelrc`
///
/// /config.bazelrc
struct BazelRC: BazelFile {
    let path: Path
    private(set) var code = ""

    init(_ root: Path) {
        path = root + "config.bazelrc"
    }

    /// build:debug --//:mode=debug
    /// bazel build --config=debug [PACKAGE:RULE]
    mutating
    func setup(config: [String : XCodeBuildSetting]?) {
        let configs = config?.keys.map { $0 } ?? []
        code = configs.map { config in
            """
            build:\(config) --//:mode=\(config)
            """
        }.withNewLine
    }
}
