//
//  LoadableRule.swift
//
//
//  Created by Yume on 2022/7/27.
//

import Foundation
import RuleBuilder

// MARK: - BuildableRule

public protocol BuildableRule {
    /// The Bazel rule symbol name, for example `"ios_application"`.
    var rule: String { get }
}

// MARK: - LoadableRule

public protocol LoadableRule: BuildableRule {
    /// The loaded Starlark module path, for example
    /// `"@build_bazel_rules_apple//apple:ios.bzl"`.
    static var target: String { get }

    /// `load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")`
    var load: String { get }

    /// Structured `load(...)` statement form.
    var loadStatement: Starlark.Statement { get }
}

public extension BuildableRule where Self: RawRepresentable, Self.RawValue == String {
    var rule: String {
        rawValue
    }
}

public extension LoadableRule {
    var load: String {
        """
        load("\(Self.target)", "\(rule)")
        """
    }

    var loadStatement: Starlark.Statement {
        .load(
            Starlark.Statement.Load(
                module: Self.target,
                symbols: [.init(rule)]
            )
        )
    }

    @available(*, deprecated, renamed: "loadStatement")
    var load2: Starlark.Statement {
        loadStatement
    }
}
