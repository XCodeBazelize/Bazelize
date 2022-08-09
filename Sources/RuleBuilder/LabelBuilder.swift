//
//  LabelBuilder.swift
//
//
//  Created by Yume on 2022/8/2.
//

import Foundation

@resultBuilder
public enum LabelBuilder {
    public typealias Target = Text & CodeText
    
    public static func buildExpression(_ expression: [String: String]) -> Target {
        Dictionary(expression)
    }
    
    public static func buildExpression(_ expression: [String?]) -> [Target] {
        expression.compactMap {$0}.map(Label.init(stringLiteral:))
    }
    
    public static func buildExpression(_ expression: String?) -> Target? {
        guard let expression = expression else { return nil }
        return Label(name: expression)
    }
    
    public static func buildExpression(_ expression: [Target]) -> [Target] {
        expression
    }
    
    public static func buildExpression(_ expression: Target?) -> Target? {
        expression
    }
    
    public static func buildBlock(_ components: Target?) -> [Target] {
        return [components].compactMap { $0 }
    }
    
    public static func buildBlock(_ components: Target?...) -> [Target] {
        return components.compactMap { $0 }
    }
    
    public static func buildBlock(_ components: [Target?]) -> [Target] {
        return components.compactMap { $0 }
    }
    
    public static func buildArray(_ components: [Target?]) -> [Target] {
        return components.compactMap { $0 }
    }
}
