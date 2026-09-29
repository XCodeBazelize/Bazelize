//
//  Select.swift
//
//
//  Created by Yume on 2022/8/18.
//

import Foundation

// MARK: - Starlark.Select

extension Starlark {
    /// What an attribute is, per condition.
    ///
    /// The two shapes are not the same question. A configuration select names
    /// every value its flag can take, so nothing can fail to match and
    /// `//conditions:default` would be a branch no build reaches. A condition —
    /// a trait, a bool flag — is on or off, and what stands when it is off has
    /// to be said, or the build fails analysis the first time someone turns it
    /// off.
    public enum Select<T: Sendable>: Sendable {
        case same(T)
        /// Keys cover the flag's whole domain: no fallback, because nothing
        /// falls through.
        case exhaustive([Label: T])
        /// A condition, and what the attribute is when it does not hold.
        case conditional([Label: T], fallback: T)

        public func map<U>(_ transform: (T) throws -> U) rethrows -> Select<U> {
            switch self {
            case .same(let value):
                return try .same(transform(value))
            case .exhaustive(let value):
                return try .exhaustive(value.mapValues(transform))
            case .conditional(let value, let fallback):
                return try .conditional(value.mapValues(transform), fallback: transform(fallback))
            }
        }
    }
}

extension Starlark.Select where T == String {
    public var starlark: Starlark.Value {
        .select(map(Starlark.Value.init))
    }
}

extension Starlark.Select where T == String? {
    public var starlark: Starlark.Value {
        .select(map {
            Starlark.Value($0) ?? None
        })
    }
}

extension Starlark.Select where T == [String] {
    public var starlark: Starlark.Value {
        .select(map {
            Starlark.Value($0) ?? .none
        })
    }
}

extension Starlark.Select where T == Bool {
    public var starlark: Starlark.Value {
        .select(map {
            Starlark.Value($0) ?? .none
        })
    }
}

// MARK: - Starlark.Select + Text

extension Starlark.Select: Text where T == Starlark.Value {
//    config_setting(
//        name = "Release",
//        values = {
//            "compilation_mode": "opt",
//        },
//    )
    /// select({
    ///    "//:Debug": "label1",
    ///    "//:Release": "label2",
    ///    "//conditions:default": "label3",
    /// })
    public var text: String {
        switch self {
        case .same(let value):
            return value.text
        case .exhaustive(let value):
            return Self.select(value)
        case .conditional(let value, let fallback):
            return Self.select(value.merging([.default: fallback]) { branch, _ in branch })
        }
    }

    private static func select(_ branches: [Starlark.Label: Starlark.Value]) -> String {
        let pairs = branches.map { key, value in
            (key.value, value)
        }
        let dictionary = Starlark.Value.dictionary(Dictionary(uniqueKeysWithValues: pairs))
        return """
        select(\(dictionary.text))
        """
    }
}
