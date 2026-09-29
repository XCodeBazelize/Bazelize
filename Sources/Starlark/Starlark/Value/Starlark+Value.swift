import Foundation

public let None: Starlark.Value = .none

// MARK: - Starlark.Value

extension Starlark {
    public static func custom(_ value: String) -> Value {
        .custom(value)
    }

    /// `allowEmpty` is for a directory something else writes into: the pattern
    /// stands for what will be there, and a package that cannot be loaded until
    /// it is cannot be the thing that puts it there.
    public static func glob(_ files: [String], exclude: [String] = [], allowEmpty: Bool = false) -> Value {
        .glob(files, exclude: exclude, allowEmpty: allowEmpty)
    }

    public indirect enum Value: Sendable, Text {
        case label(Label)
        case string(String)
        case int(Int)
        case bool(Bool)
        case array([Value])
        case dictionary([String: Value])
        case select(Starlark.Select<Value>)
        case glob([String], exclude: [String], allowEmpty: Bool)
        case custom(String)
        case none

        public static func build(@StarlarkBuilder _ builder: () -> Self) -> Self {
            builder()
        }

        // MARK: Lifecycle

        /// A Swift value as the Starlark one it stands for.
        ///
        /// A `String` is a string, not a label: the two render the same until
        /// the value carries a quote or a backslash, and then only a string
        /// survives it. A label is a label because it was written as one.
        public init?(_ any: Any?) {
            switch any {
            case let any as String?:
                guard let value = any else {
                    return nil
                }
                self = .string(value)
            case let any as [String?]:
                let result = any
                    .compactMap { $0 }
                    .map(Value.string)
                self = Value(array: result)
            case let any as [String: String]:
                self = .dictionary(any.mapValues(Value.string))

            case let any as String:
                self = .string(any)
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
                return Self.quoted(value)
            case .int(let value):
                return "\(value)"
            case .array(let value):
                let items = value.filter { !$0.isEmptyValue }
                guard !items.isEmpty else { return Value.none.text }

                return """
                [
                \(items.map(\.withComma).withNewLine.indent(1))
                ]
                """
            case .dictionary(let value):
                guard !value.isEmpty else { return Value.none.text }

                let pair = value.map { key, value in
                    """
                    \(Self.quoted(key)): \(value.text),
                    """
                }.sorted().joined(separator: "\n").indent(1)
                return ["{", pair, "}"].withNewLine
            case .bool(let value):
                return value ? "True" : "False"
            case .select(let value):
                return value.text
            case .glob(let files, let exclude, let allowEmpty):
                let asset = Value(files.sorted()) ?? .none
                var arguments = [asset.text]
                if !exclude.isEmpty {
                    let excluded = Value(exclude.sorted()) ?? .none
                    arguments.append("exclude = \(excluded.text)")
                }
                if allowEmpty {
                    arguments.append("allow_empty = True")
                }
                return "glob(\(arguments.joined(separator: ", ")))"
            case .custom(let value):
                return value
            case .none:
                return "None"
            }
        }

        /// Nothing for an attribute to take: `None`, an empty collection, or a
        /// collection of those. An attribute that is given one is an attribute
        /// that was not given anything, which is what `None` says in a
        /// generated file.
        public var isEmptyValue: Bool {
            switch self {
            case .none:
                return true
            case .array(let value):
                return value.allSatisfy(\.isEmptyValue)
            case .dictionary(let value):
                return value.isEmpty
            default:
                return false
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

        /// A Starlark string literal.
        ///
        /// Values come from Xcode build settings and from a package's own
        /// manifest, so they carry whatever was written there — a preprocessor
        /// definition like `ID=@"com.example"`, a path with a backslash. Both
        /// have to survive into the file as what they were.
        private static func quoted(_ value: String) -> String {
            let escaped = value
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            return """
            "\(escaped)"
            """
        }
    }
}

// MARK: - Starlark.Value + ExpressibleByNilLiteral

extension Starlark.Value: ExpressibleByNilLiteral {
    public init(nilLiteral _: ()) {
        self = .none
    }
}

// MARK: - Starlark.Value + ExpressibleByBooleanLiteral

extension Starlark.Value: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

// MARK: - Starlark.Value + ExpressibleByIntegerLiteral

extension Starlark.Value: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .int(value)
    }
}

// MARK: - Starlark.Value + ExpressibleByStringLiteral

extension Starlark.Value: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .label(.init(value))
    }
}

// MARK: - Starlark.Value + ExpressibleByArrayLiteral

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

// MARK: - Starlark.Value + ExpressibleByDictionaryLiteral

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

extension Array where Element == String {
    /// A list of flags as a value, so an attribute that takes one can also take
    /// a `select`. `nil` rather than an empty attribute.
    public var starlark: Starlark.Value? {
        isEmpty ? nil : .array(map(Starlark.Value.string))
    }
}
