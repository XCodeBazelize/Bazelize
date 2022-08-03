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
        return Comment(expression)
    }
    
    public static func buildExpression(_ expression: Comment) -> Target {
        return expression
    }
    
    public static func buildExpression(_ expression: Property) -> Target {
        return expression
    }
    
    public static func buildBlock(_ components: Target...) -> [Target] {
        return components
    }
    
    public static func buildBlock(_ components: [Target]...) -> [Target] {
        return components.flatMap { $0 }
    }
}
