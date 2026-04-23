//
//  CodeBuilder.swift
//
//
//  Created by Yume on 2022/7/1.
//

import Foundation
import BazelRules
import RuleBuilder
import Util

// MARK: - CodeBuilder

public final class CodeBuilder {
    private var loads: [String: Set<Starlark.Statement.LoadSymbol>] = [:]
    private var statements: [Starlark.Statement] = []
}

extension CodeBuilder {
    /// bazel_dep
    func bazelDep(name: String, version: String, repo_name: String? = nil) {
        add("bazel_dep") {
            "name" => name
            "version" => version
            if let repo_name {
                "repo_name" => repo_name
            }
        }
    }
}

extension CodeBuilder {
    func load(_ rule: Rules.Apple.General) {
        load(loadableRule: rule)
    }

    func load(_ rule: Rules.Objc) {
        load(loadableRule: rule)
    }

    func load(_ rule: Rules.Apple.IOS) {
        load(loadableRule: rule)
    }

    func load(_ rule: Rules.Apple.MacOS) {
        load(loadableRule: rule)
    }

    func load(_ rule: Rules.Apple.TVOS) {
        load(loadableRule: rule)
    }

    func load(_ rule: Rules.Apple.WatchOS) {
        load(loadableRule: rule)
    }

    func load(_ rule: Rules.Swift) {
        load(loadableRule: rule)
    }

    func load(_ rule: Rules.Config) {
        load(loadableRule: rule)
    }

    /// load function at top of the file.
    func load(module: String, symbols: [Starlark.Statement.LoadSymbol]) {
        loads[module, default: []].formUnion(symbols)
    }

    func load(_ statementLoad: Starlark.Statement.Load) {
        self.load(
            module: statementLoad.module,
            symbols: statementLoad.symbols
        )
    }

//    func load(_ code: String) {
//        statements.append(.custom(code))
//    }

    func load(loadableRule rule: LoadableRule) {
        if case let .load(statementLoad) = rule.loadStatement {
            load(statementLoad)
        }
    }
}

// MARK: - RuleBuild
extension CodeBuilder {
    func add(_ rule: Rules.Objc, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        add(rule: rule, builder: builder)
    }

    func add(_ rule: Rules.Apple.General, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        add(rule: rule, builder: builder)
    }

    func add(_ rule: Rules.Apple.IOS, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        add(rule: rule, builder: builder)
    }

    func add(_ rule: Rules.Apple.MacOS, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        add(rule: rule, builder: builder)
    }

    func add(_ rule: Rules.Apple.TVOS, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        add(rule: rule, builder: builder)
    }

    func add(_ rule: Rules.Apple.WatchOS, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        add(rule: rule, builder: builder)
    }

    func add(_ rule: Rules.Swift, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        add(rule: rule, builder: builder)
    }

    func add(_ rule: Rules.Config, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        add(rule: rule, builder: builder)
    }

    func add(_ rule: String, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        statements.append(.call(.init(rule, builder: builder)))
    }
    
    func execute(_ rule: String) {
        
    }

    /// append custom code.
    func custom(_ code: String) {
        statements.append(.custom(code))
    }

    // MARK: Private

    private func add(rule: BuildableRule, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        add(rule.rule, builder: builder)
    }

    private func add(loadableRule rule: LoadableRule, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        statements.append(.call(.init(rule.rule, builder: builder)))
    }
}

extension CodeBuilder {
    func build() -> String {
        let renderedLoads = loads
            .map { module, symbols in
                Starlark.Statement.Load(
                    module: module,
                    symbols: symbols.sorted {
                        ($0.local ?? $0.exported, $0.exported) < ($1.local ?? $1.exported, $1.exported)
                    }
                ).text
            }
            .sorted()

        let renderedStatements = statements.map(\.text)
        let sections = renderedLoads + renderedStatements
        return sections.joined(separator: "\n")
    }
}
