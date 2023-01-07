//
//  String+NewLine.swift
//
//
//  Created by Yume on 2022/7/28.
//

import Foundation

extension Array where Element == String {
    public var withNewLine: String {
        joined(separator: "\n")
    }
}

extension String {
    public var withComma: String {
        "\(self),"
    }

    public var comment: String {
        split(separator: "\n")
            .map { sub in
                sub.appending(prefix: "# ")
            }
            .joined(separator: "\n")
    }
}

extension String {
    public func delete(prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count))
    }
}

extension StringProtocol {
    public func appending(prefix: String) -> String {
        prefix + self
    }

    public func appending(suffix: String) -> String {
        self + suffix
    }
}
