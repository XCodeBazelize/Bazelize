//
//  StarlarkBool.swift
//
//
//  Created by Yume on 2022/8/17.
//

import Foundation

public struct StarlarkBool: Text, CodeText, ExpressibleByBooleanLiteral {
    // MARK: Lifecycle

    public init(_ bool: Bool) {
        self.bool = bool
    }

    public init(booleanLiteral value: Bool) {
        bool = value
    }

    // MARK: Public

    public let bool: Bool

    public var text: String {
        bool ? "True" : "False"
    }

    public var withComma: String {
        text.withComma
    }

    public var withComment: String {
        text.comment
    }
}
