//
//  Starlark.swift
//
//
//  Created by Yume on 2022/8/18.
//

import Foundation

public let None: Starlark = .none

// MARK: - Starlark

public indirect enum Starlark: Text {
    case label(String)
    case comment(String)
    case array([Starlark])
    case dictionary([String: Starlark])
    case bool(Bool)
    case select(Starlark.Select<Starlark>)
    case none

    // MARK: Lifecycle

    init?(_ any: Any?) {
        switch any {
        case let any as String?:
            guard let value = any else {
                return nil
            }
            self = .label(value)
        case let any as [String?]:
            let result = any
                .compactMap { $0 }
                .map { Starlark.label($0) }
            self = Starlark(array: result)
        case let any as [String: String]:
            let result = any.mapValues {
                Starlark.label($0)
            }
            self = .dictionary(result)

        case let any as String:
            self = .label(any)
        case let any as [Starlark]:
            self = Starlark(array: any)
        case let any as [String: Starlark]:
            self = .dictionary(any)
        case let any as Bool:
            self = .bool(any)
        default:
            self = .none
        }
    }

    // MARK: Public

    public var text: String {
        switch self {
        case .label(let value):
            return """
            "\(value)"
            """
        case .comment(let value):
            return value.comment
        case .array(let value):
            if value.isEmpty {
                return Starlark.none.text
            }

            if value.count == 1, let first = value.first {
                return first.text
            }

            return """
            [
            \(value.map(\.withComma).withNewLine.indent(1))
            ]
            """
        case .dictionary(let value):
            let pair = value.map { key, value in
                """
                "\(key)": \(value.text)
                """
            }.sorted().joined(separator: ",\n").indent(1)
            return ["{", pair,"}"].withNewLine
        case .bool(let value):
            return value ? "True" : "False"
        case .select(let value):
            return value.text
        case .none:
            return "None"
        }
    }

    // MARK: Private

    private var withComma: String {
        switch self {
        case .comment:
            return text
        case .array(let value):
            return value.map(\.withComma).withNewLine
        default:
            return text.withComma
        }
    }
}

// MARK: ExpressibleByNilLiteral

extension Starlark: ExpressibleByNilLiteral {
    public init(nilLiteral _: ()) {
        self = .none
    }
}

// MARK: ExpressibleByBooleanLiteral

extension Starlark: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

// MARK: ExpressibleByStringLiteral

extension Starlark: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .label(value)
    }
}

// MARK: ExpressibleByArrayLiteral

extension Starlark: ExpressibleByArrayLiteral {
    // MARK: Lifecycle

    public init(arrayLiteral elements: Starlark...) {
        self.init(array: elements)
    }

    public init(array: [Starlark]) {
        let values = array.filter(\.isValue)

        if values.isEmpty {
            self = .none
            return
        }

        if values.count == 1, let value = values.first {
            self = value
            return
        }

        self = .array(values)
    }

    // MARK: Private

    private var isValue: Bool {
        switch self {
        case .none:
            return false
        default:
            return true
        }
    }
}

// MARK: ExpressibleByDictionaryLiteral

extension Starlark: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, Starlark)...) {
        self = .dictionary(Dictionary(uniqueKeysWithValues: elements))
    }
}
