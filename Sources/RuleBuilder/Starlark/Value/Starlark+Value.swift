import Foundation

public let None: Starlark.Value = .none

// MARK: - Starlark.Value

extension Starlark {
    public static func custom(_ value: String) -> Value {
        .custom(value)
    }

    public static func glob(_ files: [String]) -> Value {
        .glob(files)
    }

    public indirect enum Value: Sendable, Text {
        case label(Label)
        case string(String)
        case int(Int)
        case bool(Bool)
        case array([Value])
        case dictionary([String: Value])
        case select(Starlark.Select<Value>)
        case glob([String])
        case custom(String)
        case none

        // MARK: Lifecycle

        public init?(_ any: Any?) {
            switch any {
            case let any as String?:
                guard let value = any else {
                    return nil
                }
                self = .label(.init(value))
            case let any as [String?]:
                let result = any
                    .compactMap { $0 }
                    .map { Value.label(.init($0)) }
                self = Value(array: result)
            case let any as [String: String]:
                let result = any.mapValues {
                    Value.label(.init($0))
                }
                self = .dictionary(result)

            case let any as String:
                self = .label(.init(any))
            case let any as Label:
                self = .label(any)
            case let any as [Value]:
                self = Value(array: any)
            case let any as [String: Value]:
                self = .dictionary(any)
            case let any as Int:
                self = .int(any)
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
                return value.text
            case .string(let value):
                return """
                "\(value)"
                """
            case .int(let value):
                return "\(value)"
            case .array(let value):
                if value.isEmpty {
                    return Value.none.text
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
                return ["{", pair, "}"].withNewLine
            case .bool(let value):
                return value ? "True" : "False"
            case .select(let value):
                return value.text
            case .glob(let files):
                let asset = Value(files.sorted()) ?? .none
                return """
                glob(\(asset.text))
                """
            case .custom(let value):
                return value
            case .none:
                return "None"
            }
        }

        // MARK: Private

        private var withComma: String {
            switch self {
            case .array(let value):
                return value.map(\.withComma).withNewLine
            case .custom(let value) where value.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("#"):
                return value
            default:
                return text.withComma
            }
        }
    }
}

// MARK: ExpressibleByNilLiteral

extension Starlark.Value: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .none
    }
}

// MARK: ExpressibleByBooleanLiteral

extension Starlark.Value: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

// MARK: ExpressibleByIntegerLiteral

extension Starlark.Value: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .int(value)
    }
}

// MARK: ExpressibleByStringLiteral

extension Starlark.Value: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .label(.init(value))
    }
}

// MARK: ExpressibleByArrayLiteral

extension Starlark.Value: ExpressibleByArrayLiteral {
    // MARK: Lifecycle

    public init(arrayLiteral elements: Starlark.Value...) {
        self.init(array: elements)
    }

    public init(array: [Starlark.Value]) {
        let values = array.filter(\.isValue)

        if values.isEmpty {
            self = .none
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

extension Starlark.Value: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, Starlark.Value)...) {
        self = .dictionary(Dictionary(uniqueKeysWithValues: elements))
    }
}


extension Array where Element == Starlark.Value {
    public var starlark: Starlark.Value {
        .array(self)
    }
}
