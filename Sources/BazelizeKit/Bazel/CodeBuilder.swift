//
//  CodeBuilder.swift
//
//
//  Created by Yume on 2022/7/1.
//

import BazelRules
import Foundation
import Starlark
import Util

// MARK: - CodeBuilder

public final class CodeBuilder {
    private var loads: [String: Set<Starlark.Statement.LoadSymbol>] = [:]
    private var statements: [Starlark.Statement] = []
}

extension CodeBuilder {
    func bazel_dep(name: String, version: String, repo_name: String? = nil) {
        call(
            Rules.Builtin.Call.bazel_dep(
                name: name,
                version: version,
                repo_name: repo_name))
    }
}

extension CodeBuilder {
    private func load(_ statementLoad: Starlark.Statement.Load) {
        loads[statementLoad.module, default: []].formUnion(statementLoad.symbols)
    }
}

// MARK: - RuleBuild
extension CodeBuilder {
    /// A call and the `load` its rule needs: the file never names a rule it
    /// does not load, nor loads one it does not call.
    func call(_ call: Starlark.Statement.Call) {
        if let rule = call.load {
            load(rule)
        }
        statements.append(.call(call))
    }

    /// append custom code.
    func custom(_ code: String) {
        statements.append(.custom(code))
    }
}

extension CodeBuilder {
    func build() -> String {
        let loadsStatement = loads
            .map { module, symbols in
                Starlark.Statement.Load(
                    module: module,
                    symbols: symbols.sorted {
                        ($0.local ?? $0.exported, $0.exported) < ($1.local ?? $1.exported, $1.exported)
                    })
            }
            .sorted()
            .map(\.statemenet)

        /// `load`s are one block, as are `bazel_dep`s and their overrides.
        /// Buildifier keeps these compact and separates other top-level
        /// statements with a blank line, so generation follows the same layout.
        let loaded = loadsStatement
            .map(\.text)
            .joined(separator: "\n")

        var body = ""
        var previous: Starlark.Statement?
        for statement in statements where !statement.text.isEmpty {
            if !body.isEmpty {
                body += Self.compact(previous, statement) ? "\n" : "\n\n"
            }
            body += statement.text
            previous = statement
        }

        return [loaded, body]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n") + "\n"
    }

    /// Whether buildifier would leave these two statements on adjacent lines.
    private static func compact(_ first: Starlark.Statement?, _ second: Starlark.Statement) -> Bool {
        guard
            case .call(let first)? = first,
            case .call(let second) = second
        else { return false }
        return first.name == "bazel_dep"
            && (second.name == "bazel_dep" || second.name == "single_version_override")
    }
}
