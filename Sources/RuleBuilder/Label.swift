//
//  Label.swift
//
//
//  Created by Yume on 2022/8/2.
//

import Foundation

public struct Label: ExpressibleByStringLiteral, Text, CodeText {
    public let name: String
    public init?(name: String?) {
        guard let name = name else { return nil }
        self.name = name
    }

    public init(stringLiteral value: String) {
        self.name = value
    }

    public var text: String {
        return """
        "\(name)"
        """
    }
    public var withComma: String {
        text.withComma
    }
    public var withComment: String {
        text.comment
    }
}
