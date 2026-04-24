
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
}

// MARK: - LoadableRule

public protocol LoadableRule: CallableRule {
    /// The loaded Starlark module path, for example
    /// `"@build_bazel_rules_apple//apple:ios.bzl"`.
    var module: String { get }
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
        .init(rule, builder: builder)
    }

    public func statement(
        @ArgumentBuilder builder: () -> [ArgumentBuilder.Target])
        -> Starlark.Statement
    {
        .call(call(builder: builder))
    }
}
