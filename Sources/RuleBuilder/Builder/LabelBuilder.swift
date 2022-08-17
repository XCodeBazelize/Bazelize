//
//  LabelBuilder.swift
//
//
//  Created by Yume on 2022/8/2.
//

import Foundation

// MARK: - LabelBuilder

@resultBuilder
public enum LabelBuilder {
    public typealias Target = Text & CodeText

    public static func buildExpression(_ expression: [String: String]) -> Box<Target> {
        .single(StarlarkDictionary(expression))
    }

    public static func buildExpression(_ expression: Bool) -> Box<Target> {
        .single(StarlarkBool(expression))
    }

    public static func buildExpression(_ expression: [String?]) -> Box<Target> {
        .multi(expression.compactMap { $0 }.map(StarlarkLabel.init(stringLiteral:)))
    }

    public static func buildExpression(_ expression: String?) -> Box<Target> {
        guard let expression = expression else { return .nothing }
        let label = StarlarkLabel(stringLiteral: expression)
        return .single(label)
    }

    public static func buildExpression(_ expression: [Target]) -> Box<Target> {
        .multi(expression)
    }

    public static func buildExpression(_ expression: Target?) -> Box<Target> {
        guard let expression = expression else { return .nothing }
        return .single(expression)
    }

    public static func buildFinalResult(_ box: Box<Target>) -> [Target] {
        box.flat
    }


    public static func buildBlock() -> Box<Target> {
        .nothing
    }

    public static func buildBlock(_ items: Box<Target>...) -> Box<Target> {
        .nest(items)
    }

    public static func buildIf(_ value: Box<Target>?) -> Box<Target> {
        guard let v = value else { return .nothing }
        return v
    }

    public static func buildEither(first value: Box<Target>) -> Box<Target> {
        value
    }

    public static func buildEither(second value: Box<Target>) -> Box<Target> {
        value
    }
}
