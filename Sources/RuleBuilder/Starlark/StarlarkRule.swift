//
//  StarlarkRule.swift
//
//
//  Created by Yume on 2022/8/1.
//

import Foundation
import Util

public struct StarlarkRule {
    public let rule: String
    public let properties: [PropertyBuilder.Target]
    public init(_ rule: String, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        self.rule = rule
        properties = builder()
    }

    public var text: String {
        """
        \(rule)(
        \(properties.map(\.text).withNewLine.indent(1))
        )
        """
    }
}
