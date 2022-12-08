//
//  BazelRC.swift
//
//
//  Created by Yume on 2022/12/8.
//

import Foundation
import PathKit
import PluginInterface

/// https://bazel.build/docs/configurable-attributes
struct BazelRC: BazelFile {
    let path: Path
    private(set) var code = ""

    init(_ root: Path) {
        path = root + ".bazelrc"
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
