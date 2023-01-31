//
//  PluginBuiltin.swift
//
//
//  Created by Yume on 2023/1/31.
//

// MARK: - PluginBuiltin

class PluginBuiltin {
    unowned let kit: Kit
    init(_ kit: Kit) {
        self.kit = kit
    }

    var name: String { "Builtin Plugin" }
    var description: String { "" }
    var version: String { "0.0.1" }
    var url: String { "Builtin" }

    var module: String? { nil }
    var workspace: String? { nil }
    var build: String? { nil }
    var target: [String: [String]]? { nil }
    var custom: [Custom]? { nil }

    var tip: String? { nil }

    struct Custom {
        let path: String
        let content: String
    }
}
