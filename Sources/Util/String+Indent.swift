//
//  indent.swift
//  
//
//  Created by Yume on 2022/6/7.
//

import Foundation

extension String {
    public func indent(_ count: Int, _ word: String = "    ") -> String {
        let prefix = Array(repeating: word, count: count).joined(separator: "")
        return self
            .split(separator: "\n")
            .map { sub in
                prefix + sub
            }
            .joined(separator: "\n")
    }
}

@resultBuilder
public struct TextBuilder {
    
//    let prefix: String
//    let suffix: String
//    let indent: String
//    init(_ prefix: String = "", _ suffix: String = "", _ indent: String = "    ") {
//        self.prefix = prefix
//        self.suffix = suffix
//        self.indent = indent
//    }
    
    public static func buildBlock(_ components: String...) -> String {
        return components.joined(separator: "\n").indent(1)
    }
    
//    public static func buildFinalResult(_ component: String) -> String {
//        ""
//    }
}
//_ prefix: String = "", _ suffix: String = "",
public func text(@TextBuilder builder: () -> String) -> String {
    return builder()
//    return [prefix, builder(), suffix].joined(separator: "\n")
}
