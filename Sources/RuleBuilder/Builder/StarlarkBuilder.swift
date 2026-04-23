//
//  StarlarkBuilder.swift
//
//
//  Created by Yume on 2022/8/18.
//

import Foundation

@resultBuilder
public enum StarlarkBuilder {
    // MARK: - expression + basic
    
    public static func buildExpression(_ expression: Starlark.Label) -> Starlark.Value {
        .label(expression)
    }
    
    public static func buildExpression(_ expression: String) -> Starlark.Value {
        .string(expression)
    }
    
    public static func buildExpression(_ expression: Int) -> Starlark.Value {
        .int(expression)
    }

    public static func buildExpression(_ expression: Bool) -> Starlark.Value {
        .bool(expression)
    }
    
    public static func buildExpression(_ expression: [Starlark.Value]) -> Starlark.Value {
        .array(expression)
    }
    
    public static func buildExpression(_ expression: [String: Starlark.Value]) -> Starlark.Value {
        .dictionary(expression)
    }
    
    public static func buildExpression(_ expression: Starlark.Select<Starlark.Value>) -> Starlark.Value {
        .select(expression)
    }
    
    // MARK: - expression + basic array
    
    public static func buildExpression(_ expression: [Starlark.Label]) -> Starlark.Value {
        expression
            .map { value in
                Starlark.Value.label(value)
            }
            .starlark
    }
    
    public static func buildExpression(_ expression: [String]) -> Starlark.Value {
        expression
            .map { value in
                Starlark.Value.string(value)
            }
            .starlark
    }
    
    public static func buildExpression(_ expression: [Int]) -> Starlark.Value {
        expression
            .map { value in
                Starlark.Value.int(value)
            }
            .starlark
    }

    public static func buildExpression(_ expression: [Bool]) -> Starlark.Value {
        expression
            .map { value in
                Starlark.Value.bool(value)
            }
            .starlark
    }
    
    // MARK: - expression + other
    
    public static func buildExpression(_ expression: String?) -> Starlark.Value? {
        .init(expression)
    }
    
    public static func buildExpression(_ expression: Starlark.Value) -> Starlark.Value {
        expression
    }

    public static func buildExpression(_ expression: [String: String]) -> Starlark.Value {
        Starlark.Value(expression) ?? None
    }

    public static func buildExpression(_ expression: [String]?) -> Starlark.Value {
        Starlark.Value(expression) ?? None
    }

    public static func buildExpression(_ expression: [String?]) -> Starlark.Value {
        Starlark.Value(expression) ?? None
    }

    // MARK: -
    
    public static func buildBlock(_ components: Starlark.Value?...) -> Starlark.Value {
        let result = components.compactMap { $0 }
        return .init(result) ?? None
    }

    public static func buildOptional(_ component: Starlark.Value?) -> Starlark.Value {
        component ?? None
    }
}
