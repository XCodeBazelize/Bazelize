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
    public static func buildExpression(_ expression: [String?]) -> [Target] {
        return expression.compactMap {$0}.map(Label.init(stringLiteral:))
    }
    
    public static func buildExpression(_ expression: String?) -> Target? {
        guard let expression = expression else {return nil}
        return Label(name: expression)
    }
    
    public static func buildExpression(_ expression: [Label]) -> [Target] {
        return expression
    }
    
    public static func buildExpression(_ expression: Label) -> Target {
        return expression
    }
    
    public static func buildExpression(_ expression: Dictionary) -> Target {
        return expression
    }
    
    public static func buildExpression(_ expression: Comment) -> Target {
        return expression
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
    
//    public static func buildBlock(_ components: String?) -> [Label] {
//        return [Label(name: components)].compactMap { $0 }
//    }
//
//    public static func buildBlock(_ components: String?...) -> [Label] {
//        return components.compactMap(Label.init(name:))
//    }
//
//    public static func buildBlock(_ components: [String?]) -> [Label] {
//        return components.compactMap(Label.init(name:))
//    }
//
//    public static func buildArray(_ components: [String?]) -> [Label] {
//        return components.compactMap(Label.init(name:))
//    }

//    public static func buildBlock(_ components: String) -> [Label] {
//        return [.init(stringLiteral: components)]
//    }
//
//    public static func buildBlock(_ components: String...) -> [Label] {
//        return components.map(Label.init(stringLiteral:))
//    }
//
//    public static func buildBlock(_ components: [String]) -> [Label] {
//        components.map(Label.init(stringLiteral:))
//    }
//
//    public static func buildArray(_ components: [String]) -> [Label] {
//        components.map(Label.init(stringLiteral:))
//    }
}
