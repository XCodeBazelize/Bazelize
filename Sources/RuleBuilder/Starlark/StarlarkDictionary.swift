//
//  StarlarkDictionary.swift
//
//
//  Created by Yume on 2022/8/5.
//

import Foundation

public struct StarlarkDictionary: Text, CodeText {
    // MARK: Lifecycle

    public init(_ dictionary: [String: String]) {
        self.dictionary = dictionary
    }

    // MARK: Public

    public let dictionary: [String: String]


    public var text: String {
        let pair = dictionary.map { key, value in
            """
            "\(key)": "\(value)"
            """
        }.sorted().joined(separator: ",\n").indent(1)
        return ["{", pair,"}"].withNewLine
    }

    public var withComma: String {
        text.withComma
    }

    public var withComment: String {
        text.comment
    }
}
