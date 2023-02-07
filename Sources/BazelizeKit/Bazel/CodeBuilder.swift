//
//  CodeBuilder.swift
//
//
//  Created by Yume on 2022/7/1.
//

import Foundation
import RuleBuilder
import Util

// MARK: - CodeBuilder

public final class CodeBuilder {
    private var loads: Set<String> = .init()
    private var codes: [String] = []
}

extension CodeBuilder {
    private var _code: String {
        get { "" }
        set { codes.append(newValue) }
    }
}

extension CodeBuilder {
    /// bazel_dep
    func moduleDep(name: String, version _: String, repo_name: String? = nil) {
        add("bazel_dep") {
            "name" => name
            "version" => name
            "repo_name" => repo_name
        }
    }
}

extension CodeBuilder {
    func load(_ rule: RulesObjc) {
        load(loadableRule: rule)
    }

    func load(_ rule: RulesApple.IOS) {
        load(loadableRule: rule)
    }

    func load(_ rule: RulesApple.Mac) {
        load(loadableRule: rule)
    }

    func load(_ rule: RulesApple.TV) {
        load(loadableRule: rule)
    }

    func load(_ rule: RulesApple.Watch) {
        load(loadableRule: rule)
    }

    func load(_ rule: RulesSwift) {
        load(loadableRule: rule)
    }

    func load(_ rule: RulesConfig) {
        load(loadableRule: rule)
    }

    /// load function at top of the file.

    func load(_ code: String) {
        loads.insert(code)
    }

    func load(loadableRule rule: LoadableRule) {
        load(rule.load)
    }
}

// MARK: - RuleBuild
extension CodeBuilder {
    func add(_ rule: RulesObjc, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        add(rule: rule, builder: builder)
    }

    func add(_ rule: RulesApple.IOS, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        add(rule: rule, builder: builder)
    }

    func add(_ rule: RulesApple.Mac, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        add(rule: rule, builder: builder)
    }

    func add(_ rule: RulesApple.TV, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        add(rule: rule, builder: builder)
    }

    func add(_ rule: RulesApple.Watch, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        add(rule: rule, builder: builder)
    }

    func add(_ rule: RulesSwift, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        add(rule: rule, builder: builder)
    }

    func add(_ rule: RulesConfig, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        add(rule: rule, builder: builder)
    }

    func add(_ rule: String, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        custom(StarlarkRule(rule, builder: builder).text)
    }

    /// append custom code.

    func custom(_ code: String) {
        _code = code
    }

    // MARK: Private

    private
    func add(rule: BuildableRule, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        add(rule.rule, builder: builder)
    }

    private
    func add(loadableRule rule: LoadableRule, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        custom(StarlarkRule(rule.rule, builder: builder).text)
    }
}

extension CodeBuilder {
    func build() -> String {
        let loads = loads.sorted().joined(separator: "\n")
        let codes: [String]
        if loads.isEmpty {
            codes = self.codes
        } else {
            codes = [loads] + self.codes
        }

        return codes.joined(separator: "\n\n")
    }
}
