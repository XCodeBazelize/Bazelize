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
            .withNewLine
    }
}

