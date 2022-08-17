//
//  StarlarkNone.swift
//
//
//  Created by Yume on 2022/8/17.
//

import Foundation

public let None: StarlarkNone = .none

// MARK: - StarlarkNone

public enum StarlarkNone: Text, CodeText, ExpressibleByNilLiteral {
    case none

    public init(nilLiteral _: ()) {
        self = .none
    }

    public var text: String {
        "None"
    }

    public var withComment: String {
        text.comment
    }

    public var withComma: String {
        text.withComma
    }
}
