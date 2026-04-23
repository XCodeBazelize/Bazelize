
//
//  LoadableRule.swift
//
//
//  Created by Yume on 2022/7/27.
//

import Foundation
import RuleBuilder

// MARK: - CallableRule

public protocol CallableRule {
    /// The Bazel rule symbol name, for example `"ios_application"`.
    var rule: String { get }
}

// MARK: - LoadableRule

public protocol LoadableRule: CallableRule {
    /// The loaded Starlark module path, for example
    /// `"@build_bazel_rules_apple//apple:ios.bzl"`.
    var module: String { get }
}

public extension CallableRule where Self: RawRepresentable, Self.RawValue == String {
    var rule: String {
        rawValue
    }
}

public extension CallableRule {
    func call(
        @ArgumentBuilder builder: () -> [ArgumentBuilder.Target]
    ) -> Starlark.Statement.Call {
        .init(rule, builder: builder)
    }

    func statement(
        @ArgumentBuilder builder: () -> [ArgumentBuilder.Target]
    ) -> Starlark.Statement {
        .call(call(builder: builder))
    }
}
