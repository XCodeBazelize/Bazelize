//
//  PropertyBuilder.swift
//
//
//  Created by Yume on 2022/8/2.
//

import Foundation

@resultBuilder
public enum PropertyBuilder {
    public typealias Target = Text

    public static func buildExpression(_ expression: String) -> Target {
        StarlarkComment(expression)
    }

    public static func buildExpression(_ expression: Target) -> Target {
        expression
    }

    public static func buildBlock(_ components: Target...) -> [Target] {
        components
    }

    public static func buildBlock(_ components: [Target]...) -> [Target] {
        components.flatMap { $0 }
    }
}
