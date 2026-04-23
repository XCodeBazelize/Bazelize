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

            let renderedArguments = arguments
                .map(\.text)
                .joined(separator: "\n")
                .indent(1)
            return """
            \(name)(
            \(renderedArguments)
            )
            """
        }
    }

    public enum Argument: Sendable, Text {
        case comment(Starlark.Comment)
        case positional(Starlark.Value)
        case named(String, Starlark.Value)

        public static func named(_ name: String, @StarlarkBuilder builder: () -> Starlark.Value) -> Self {
            .named(name, builder())
        }

        public static func comment(_ value: String) -> Self {
            .comment(.init(value))
        }

        public var text: String {
            switch self {
            case let .positional(value):
                return "\(value.text),"
            case let .comment(comment):
                return comment.text
            case let .named(name, value):
                let renderedValue: String
                switch value {
                case .none:
                    renderedValue = "# \(name) = None,"
                default:
                    renderedValue = "\(name) = \(value.text),"
                }

                return renderedValue
            }
        }
    }
}
