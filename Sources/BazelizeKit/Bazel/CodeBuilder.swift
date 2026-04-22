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
    func bazelDep(name: String, version: String, repo_name: String? = nil) {
        add("bazel_dep") {
            "name" => name
            "version" => version
            "repo_name" => repo_name
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

    func load(_ code: String) {
        loads.insert(code)
    }

    func load(loadableRule rule: LoadableRule) {
        load(rule.load)
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
        custom(StarlarkRule(rule, builder: builder).text)
    }
    
    func execute(_ rule: String,) {
        
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
