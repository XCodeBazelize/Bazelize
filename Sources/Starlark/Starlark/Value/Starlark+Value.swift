import Foundation

public let None: Starlark.Value = .none

// MARK: - Starlark.Value

extension Starlark {
    public static func custom(_ value: String) -> Value {
        .custom(value)
    }

    /// A multi-line string literal: `"""`, the text, `"""`.
    ///
    /// Written the way buildifier writes one, which is the only way it will
    /// leave it alone.
    public static func tripleQuoted(_ value: String) -> Value {
        .custom("\"\"\"\n\(Format.escaped(value, triple: true))\n\"\"\"")
    }

    /// `allowEmpty` is for a directory something else writes into: the pattern
    /// stands for what will be there, and a package that cannot be loaded until
    /// it is cannot be the thing that puts it there.
    public static func glob(_ files: [String], exclude: [String] = [], allowEmpty: Bool = false) -> Value {
        .glob(files, exclude: exclude, allowEmpty: allowEmpty)
    }

    /// Patterns as a value: only a pattern with a wildcard in it is globbed.
    ///
    /// `glob(["a/b.xib"])` is that one file with a way to be silently empty
    /// instead, which is what buildifier's `constant-glob` says out loud. A
    /// pattern that names a file is that file.
    public static func paths(_ patterns: [String], exclude: [String] = [], allowEmpty: Bool = false) -> Value {
        var seen: Set<String> = []
        let unique = patterns.filter { seen.insert($0).inserted }
        let wildcards = unique.filter { $0.contains(where: isWildcard) }
        let named = unique.filter { !$0.contains(where: isWildcard) }

        guard !wildcards.isEmpty else {
            return .array(named.map(Value.string))
        }
        guard !named.isEmpty else {
            return .glob(wildcards, exclude: exclude, allowEmpty: allowEmpty)
        }

        return .concat([
            .array(named.map(Value.string)),
            .glob(wildcards, exclude: exclude, allowEmpty: allowEmpty),
        ])
    }

    private static func isWildcard(_ character: Character) -> Bool {
        character == "*" || character == "?" || character == "["
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
        /// `[":a"] + select({…})`: an attribute that is partly unconditional
        /// and partly not.
        case concat([Value])
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
                /// An empty list is a list: an attribute given one says so with
                /// `None` instead, which the argument it belongs to decides.
                let items = value.filter { !$0.isEmptyValue }
                guard !items.isEmpty else { return "[]" }

                return """
                [
                \(items.map(\.withComma).withNewLine.indent(1))
                ]
                """
            case .dictionary(let value):
                guard !value.isEmpty else { return "{}" }

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
                if allowEmpty {
                    arguments.append("allow_empty = True")
                }
                if !exclude.isEmpty {
                    let excluded = Value(exclude.sorted()) ?? .none
                    arguments.append("exclude = \(excluded.text)")
                }
                /// One argument stays on the call, the way buildifier leaves
                /// `glob([...])`; more than one gets a line each, because that
                /// is what it breaks them into.
                guard arguments.count > 1 else {
                    return "glob(\(arguments[0]))"
                }
                return """
                glob(
                \(arguments.map(\.withComma).withNewLine.indent(1))
                )
                """
            case .concat(let value):
                let parts = value.filter { !$0.isEmptyValue }
                guard let first = parts.first else { return Value.none.text }
                guard parts.count > 1 else { return first.text }
                return parts.map(\.text).joined(separator: " + ")
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
            case .concat(let value):
                return value.allSatisfy(\.isEmptyValue)
            case .dictionary(let value):
                return value.isEmpty
            default:
                return false
            }
        }

        /// The same value with every list of plain strings in buildifier's
        /// order, duplicates dropped.
        ///
        /// A list of anything else is left alone: the order of a list that
        /// holds a call or a dictionary is the order it was built in. A list
        /// of lists is one list — that is how it is written out — so it sorts
        /// as one. The lists either side of a `+` and the ones a `select` maps
        /// to are reached too, which is as far as buildifier goes.
        public var sortedStrings: Self {
            switch self {
            case .array:
                guard let keyed = sortableStrings else { return self }

                var seen: Set<String> = []
                let sorted = keyed
                    .sorted { Starlark.Format.precedes($0.key, $1.key) }
                    .filter { seen.insert($0.key).inserted }
                    .map(\.value)
                return .array(sorted)
            case .concat(let values):
                return .concat(values.map(\.sortedStrings))
            case .select(let select):
                return .select(select.map(\.sortedStrings))
            default:
                return self
            }
        }

        /// Every string this value writes out, in writing order, or nothing if
        /// it writes anything else.
        private var sortableStrings: [(key: String, value: Self)]? {
            switch self {
            case .string(let value):
                return [(value, self)]
            case .label(let value):
                return [(value.value, self)]
            case .array(let values):
                var result: [(key: String, value: Self)] = []
                for value in values {
                    guard let strings = value.sortableStrings else { return nil }
                    result += strings
                }
                return result
            default:
                return nil
            }
        }

        /// The same value with every label written the short way.
        ///
        /// Reached as far as buildifier reaches: the value itself, the lists
        /// either side of a `+`, and what a `select` maps its conditions to.
        public var shortenedLabels: Self {
            switch self {
            case .string(let value):
                return .string(Starlark.Format.shortened(label: value))
            case .label(let value):
                return .label(.init(Starlark.Format.shortened(label: value.value)))
            case .array(let values):
                return .array(values.map(\.shortenedLabels))
            case .concat(let values):
                return .concat(values.map(\.shortenedLabels))
            case .select(let select):
                return .select(select.map(\.shortenedLabels))
            default:
                return self
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

        /// A Starlark string literal, escaped the way buildifier writes one.
        ///
        /// Values come from Xcode build settings and from a package's own
        /// manifest, so they carry whatever was written there — a preprocessor
        /// definition like `ID=@"com.example"`, a path with a backslash, a
        /// copyright sign. Both have to survive into the file as what they
        /// were, and a BUILD file is read as Latin-1: every control and high
        /// byte is octal, the way buildifier would rewrite it.
        private static func quoted(_ value: String) -> String {
            """
            "\(Starlark.Format.escaped(value))"
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
