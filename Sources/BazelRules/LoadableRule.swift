
//
//  LoadableRule.swift
//
//
//  Created by Yume on 2022/7/27.
//

import Foundation
import Starlark

// MARK: - CallableRule

public protocol CallableRule {
    /// The Bazel rule symbol name, for example `"ios_application"`.
    var rule: String { get }

    /// The `load` a call to this rule needs; `nil` for a rule Bazel defines
    /// itself.
    var load: Starlark.Statement.Load? { get }
}

// MARK: - LoadableRule

public protocol LoadableRule: CallableRule {
    /// The loaded Starlark module path, for example
    /// `"@build_bazel_rules_apple//apple:ios.bzl"`.
    var module: String { get }
}

extension CallableRule {
    public var load: Starlark.Statement.Load? {
        nil
    }
}

extension LoadableRule {
    public var load: Starlark.Statement.Load? {
        .init(module: module, symbols: [.init(rule)])
    }
}

extension CallableRule where Self: RawRepresentable, Self.RawValue == String {
    public var rule: String {
        rawValue
    }
}

extension CallableRule {
    public func call(
        @ArgumentBuilder builder: () -> [ArgumentBuilder.Target])
        -> Starlark.Statement.Call
    {
        .init(rule, load: load, builder: builder)
    }

    public func statement(
        @ArgumentBuilder builder: () -> [ArgumentBuilder.Target])
        -> Starlark.Statement
    {
        .call(call(builder: builder))
    }
}
