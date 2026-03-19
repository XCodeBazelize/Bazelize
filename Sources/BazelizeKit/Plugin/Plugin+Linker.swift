//
//  PluginLinker.swift
//
//
//  Created by Yume on 2023/2/3.
//

import Foundation

/// deps
/// "@rules_apple_linker//:zld"
/// "@rules_apple_linker//:lld"

/// https://github.com/keith/rules_apple_linker
class PluginLinker: PluginBuiltin {
    override func module(_ builder: CodeBuilder) {
        builder.custom(
            """
            bazel_dep(name = "rules_apple_linker", version = "0.3.0")
            """
        )
    }
}
