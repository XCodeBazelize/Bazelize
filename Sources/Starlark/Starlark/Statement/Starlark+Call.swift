import Foundation
import Util

extension Starlark.Statement {
    public struct Call: Text {
        public let name: String
        public let arguments: [Argument]

        public init(_ name: String, _ arguments: [Argument] = []) {
            self.name = name
            self.arguments = arguments
        }

        public init(_ name: String, @ArgumentBuilder builder: () -> [ArgumentBuilder.Target]) {
            self.init(name, builder())
        }

        public var text: String {
            guard !arguments.isEmpty else {
                return "\(name)()"
            }

            let renderedArguments = Self.ordered(arguments, of: name)
                .map(\.text)
                .joined(separator: "\n")
                .indent(1)
            return """
            \(name)(
            \(renderedArguments)
            )
            """
        }

        /// The arguments in the order buildifier puts them: the trailing run of
        /// named arguments sorts by priority, then name, and the strings given
        /// to an attribute whose order means nothing sort too.
        ///
        /// Only the trailing run, because a positional argument or a comment
        /// line stands where it was written and everything before it with it.
        private static func ordered(_ arguments: [Argument], of rule: String) -> [Argument] {
            var start = arguments.count
            while start > 0, case .named = arguments[start - 1] {
                start -= 1
            }

            let sorted = arguments[start...]
                .enumerated()
                .sorted { lhs, rhs in
                    let left = Starlark.Format.priority(rule: rule, argument: lhs.element.name)
                    let right = Starlark.Format.priority(rule: rule, argument: rhs.element.name)
                    guard left == right else { return left < right }
                    guard lhs.element.name == rhs.element.name else {
                        return lhs.element.name < rhs.element.name
                    }
                    return lhs.offset < rhs.offset
                }
                .map(\.element)
                .map { argument -> Argument in
                    guard case .named(let name, let value) = argument else { return argument }
                    /// Labels are canonicalised before the list is ordered, so
                    /// the order is the one the short form sorts in.
                    var result = value
                    if Starlark.Format.isLabel(rule: rule, argument: name) {
                        result = result.shortenedLabels
                    }
                    if Starlark.Format.sorts(rule: rule, argument: name) {
                        result = result.sortedStrings
                    }
                    return .named(name, result)
                }

            return Array(arguments[..<start]) + sorted
        }
    }

    public enum Argument: Sendable, Text {
        case comment(Starlark.Comment)
        case positional(Starlark.Value)
        case named(String, Starlark.Value)

        /// The attribute this argument gives a value to, if it names one.
        var name: String {
            guard case .named(let name, _) = self else { return "" }
            return name
        }

        public static func named(_ name: String, @StarlarkBuilder builder: () -> Starlark.Value) -> Self {
            .named(name, builder())
        }

        public static func comment(_ value: String) -> Self {
            .comment(.init(value))
        }

        public var text: String {
            switch self {
            case .positional(let value):
                return "\(value.text),"
            case .comment(let comment):
                return comment.text
            case .named(let name, let value):
                /// An attribute given nothing is an attribute that was not
                /// given anything: an empty list says the same as `None` and
                /// reads as a decision that was made.
                guard !value.isEmptyValue else {
                    return "# \(name) = None,"
                }
                return "\(name) = \(value.text),"
            }
        }
    }
}
