//
//  String+NewLine.swift
//  
//
//  Created by Yume on 2022/7/28.
//

import Foundation

extension Array where Element == String {
    public var withNewLine: String {
        self.joined(separator: "\n")
    }
}

extension String {
    public var withComma: String {
        return "\(self),"
    }
    
    public var comment: String {
        return self
            .split(separator: "\n")
            .map { sub in
                sub.appending(prefix: "# ")
            }
            .joined(separator: "\n")
    }
}

extension StringProtocol {
    public func appending(prefix: String) -> String {
        return prefix + self
    }
    
    public func appending(suffix: String) -> String {
        return self + suffix
    }
}
