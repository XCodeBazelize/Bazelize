//
//  StarlarkLabel.swift
//
//
//  Created by Yume on 2022/8/2.
//

import Foundation

public struct StarlarkLabel: ExpressibleByStringLiteral, Text, CodeText {
    // MARK: Lifecycle

    public init?(name: String?) {
        guard let name = name else { return nil }
        self.name = name
    }

    public init(stringLiteral value: String) {
        name = value
    }

    // MARK: Public

    public let name: String

    public var text: String {
        """
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
