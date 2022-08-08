//
//  Dictionary.swift
//  
//
//  Created by Yume on 2022/8/5.
//

import Foundation

public struct Dictionary: Text, CodeText {
    public let dictionary: [String: String]
    
    public var text: String {
        let pair = dictionary.map { (key, value) in
            return """
            "\(key)": "\(value)"
            """
        }.joined(separator: ",\n").indent(1)
        return ["{", pair,"}"].withNewLine
    }
    
    public var withComma: String {
        text.withComma
    }
    public var withComment: String {
        text.comment
    }
}
