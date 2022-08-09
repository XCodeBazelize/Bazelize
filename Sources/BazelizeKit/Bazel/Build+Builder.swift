//
//  Build+Builder.swift
//
//
//  Created by Yume on 2022/7/1.
//

import Foundation
import RuleBuilder
import Util

// MARK: - Build

struct Build {
    struct Builder {
        private var codes: [String] = []
    }
}

extension Build.Builder {
    private var _code: String {
        get { "" }
        set { codes.append(newValue) }
    }
}

extension Build.Builder {
    // MARK: Internal

    mutating
    func load(_ rule: RulesApple.IOS) {
        load(loadableRule: rule)
    }

    mutating
    func load(_ rule: RulesApple.Mac) {
        load(loadableRule: rule)
    }

    mutating
    func load(_ rule: RulesApple.TV) {
        load(loadableRule: rule)
    }

    mutating
    func load(_ rule: RulesApple.Watch) {
        load(loadableRule: rule)
    }

    mutating
    func load(_ rule: RulesSwift) {
        load(loadableRule: rule)
    }

    mutating
    func load(_ rule: RulesConfig) {
        load(loadableRule: rule)
    }

    /// load function at top of the file.
    mutating
    func load(_ code: String) {
        codes.insert(code, at: 0)
    }

    // MARK: Private

    private mutating
    func load(loadableRule rule: LoadableRule) {
        load(rule.load)
    }
}

// MARK: - RuleBuild
extension Build.Builder {
    // MARK: Internal

    mutating
    func add(_ rule: RulesApple.IOS, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        add(rule: rule, builder: builder)
    }

    mutating
    func add(_ rule: RulesApple.Mac, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        add(rule: rule, builder: builder)
    }

    mutating
    func add(_ rule: RulesApple.TV, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        add(rule: rule, builder: builder)
    }

    mutating
    func add(_ rule: RulesApple.Watch, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        add(rule: rule, builder: builder)
    }

    mutating
    func add(_ rule: RulesSwift, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        add(rule: rule, builder: builder)
    }

    mutating
    func add(_ rule: RulesConfig, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        add(rule: rule, builder: builder)
    }

    mutating
    func add(_ rule: String, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        custom(Rule(rule, builder: builder).text)
    }

    /// append custom code.
    mutating
    func custom(_ code: String) {
        _code = code
    }

    // MARK: Private

    private mutating
    func add(rule: BuildableRule, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        add(rule.rule, builder: builder)
    }

    private mutating
    func add(loadableRule rule: LoadableRule, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        custom(Rule(rule.rule, builder: builder).text)
    }
}

extension Build.Builder {
    func build() -> String {
        codes.joined(separator: "\n")
    }
}
