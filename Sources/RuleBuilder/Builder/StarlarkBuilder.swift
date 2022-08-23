//
//  StarlarkBuilder.swift
//
//
//  Created by Yume on 2022/8/18.
//

import Foundation

@resultBuilder
public enum StarlarkBuilder {
    public static func buildBlock(_ components: Starlark?...) -> Starlark {
        .init(components.compactMap { $0 }) ?? None
    }

    // MARK: - expression
    public static func buildExpression(_ expression: Starlark) -> Starlark {
        expression
    }

    public static func buildExpression(_ expression: [Starlark]) -> Starlark {
        Starlark(array: expression)
    }

    public static func buildExpression(_ expression: [String: String]) -> Starlark {
        .init(expression) ?? None
    }

    public static func buildExpression(_ expression: [String]?) -> Starlark {
        .init(expression) ?? None
    }

    public static func buildExpression(_ expression: [String?]) -> Starlark {
        .init(expression) ?? None
    }

    public static func buildExpression(_ expression: String?) -> Starlark? {
        .init(expression)
    }

    public static func buildExpression(_ expression: Bool) -> Starlark {
        .bool(expression)
    }

    public static func buildExpression(_ expression: Starlark.Select<Starlark>) -> Starlark {
        .select(expression)
    }
}
