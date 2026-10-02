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
    /// What is left of the string after the prefix, or `nil` when it does not
    /// start with one.
    ///
    /// Not the string itself when the prefix is absent: a caller that wants
    /// that says so — `path.delete(prefix: root) ?? path` — and one that wants
    /// something else can have it, which is what a non-optional answer took
    /// away.
    public func delete(prefix: String) -> String? {
        guard hasPrefix(prefix) else { return nil }
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
