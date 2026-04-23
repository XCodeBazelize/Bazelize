//
//  StarlarkBuilder.swift
//
//
//  Created by Yume on 2022/8/18.
//

import Foundation

@resultBuilder
public enum StarlarkBuilder {
    public static func buildBlock(_ components: Starlark.Value?...) -> Starlark.Value {
        let result = components.compactMap { $0 }
        return .init(result) ?? None
    }

    // MARK: - expression
    public static func buildExpression(_ expression: Starlark.Value) -> Starlark.Value {
        expression
    }

    public static func buildExpression(_ expression: [Starlark.Value]) -> Starlark.Value {
        Starlark.Value(array: expression)
    }

    public static func buildExpression(_ expression: [String: String]) -> Starlark.Value {
        .init(expression) ?? None
    }

    public static func buildExpression(_ expression: [String]?) -> Starlark.Value {
        .init(expression) ?? None
    }

    public static func buildExpression(_ expression: [String?]) -> Starlark.Value {
        .init(expression) ?? None
    }

    public static func buildExpression(_ expression: String?) -> Starlark.Value? {
        .init(expression)
    }

//    public static func buildExpression(_ expression: Starlark.Statement.Argument.Comment) -> Starlark.Value {
//        .custom(expression.text)
//    }

    public static func buildExpression(_ expression: Bool) -> Starlark.Value {
        .bool(expression)
    }

    public static func buildExpression(_ expression: Starlark.Select<Starlark.Value>) -> Starlark.Value {
        .select(expression)
    }

    public static func buildOptional(_ component: Starlark.Value?) -> Starlark.Value {
        component ?? None
    }
}
