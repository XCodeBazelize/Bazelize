//
//  StarlarkComment.swift
//
//
//  Created by Yume on 2022/8/2.
//

import Foundation

public struct StarlarkComment: Text, CodeText {
    public let description: String
    public init(_ description: String) {
        self.description = description
    }

    public var text: String {
        description.comment
    }

    public var withComma: String {
        text
    }

    public var withComment: String {
        text
    }
}
