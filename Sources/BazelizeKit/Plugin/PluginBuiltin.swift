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

    /// Module.bazel
    func module(_: CodeBuilder) { }
    /// WORKSPACE
    func workspace(_: CodeBuilder) { }
    /// BUILD
    func build(_: CodeBuilder) { }

    var target: [String: [String]]? { nil }
    var custom: [Custom]? { nil }

    var tip: String? { nil }

    struct Custom {
        let path: String
        let content: String
    }
}
