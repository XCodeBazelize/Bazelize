//
//  Select.swift
//
//
//  Created by Yume on 2022/8/18.
//

import Foundation

// MARK: - Select

extension Starlark {
    public enum Select<T> {
        case same(T)
        case various([String: T])

        public func map<U>(_ transform: (T) throws -> U) rethrows -> Select<U> {
            switch self {
            case .same(let value):
                return try .same(transform(value))
            case .various(let value):
                return try .various(value.mapValues(transform))
            }
        }
    }
}

extension Starlark.Select where T == String {
    public var starlark: Starlark.Select<Starlark> {
        map(Starlark.init)
    }
}

extension Starlark.Select where T == String? {
    public var starlark: Starlark.Select<Starlark> {
        map {
            Starlark($0) ?? None
        }
    }
}

extension Starlark.Select where T == [String] {
    public var starlark: Starlark.Select<Starlark> {
        map {
            Starlark($0) ?? .none
        }
    }
}

// MARK: - Starlark.Select + Text

extension Starlark.Select: Text where T == Starlark {
    /// select({
    ///    "//:Debug": "label1",
    ///    "//:Release": "label2",
    ///    "//conditions:default": "label3",
    /// })
    public var text: String {
        switch self {
        case .same(let value):
            return value.text
        case .various(let value):
            let pair = value.map { key, value in
                ("//:\(key)", value)
            }
            let newValue = Starlark.dictionary(Dictionary(uniqueKeysWithValues: pair))
            return """
            select(\(newValue.text))
            """
        }
    }
}
