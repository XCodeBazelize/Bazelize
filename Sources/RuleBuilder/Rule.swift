//
//  Rule.swift
//
//
//  Created by Yume on 2022/8/1.
//

import Foundation
import Util

public struct Rule {
    public let rule: String
    public let properties: [PropertyBuilder.Target]
    public init(_ rule: String, @PropertyBuilder builder: () -> [PropertyBuilder.Target]) {
        self.rule = rule
        self.properties = builder()
    }

    public var text: String {
        return """
        \(rule)(
        \(properties.map(\.text).withNewLine.indent(1))
        )
        """
    }
}
