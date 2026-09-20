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
    let dep: BazelDep.AppleLinker = .latest

    override func module(_ builder: CodeBuilder) {
        builder.bazel_dep(
            name: "rules_apple_linker",
            version: dep.rawValue)
    }
}
