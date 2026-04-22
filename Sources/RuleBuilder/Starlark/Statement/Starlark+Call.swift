import Foundation

extension Starlark.Statement {
    public struct Call: Text {
        public let name: String
        public let arguments: [Argument]

        public init(_ name: String, _ arguments: [Argument] = []) {
            self.name = name
            self.arguments = arguments
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

    public enum Argument: Text {
        case positional(Starlark.Value)
        case named(String, Starlark.Value)

        public var text: String {
            switch self {
            case let .positional(value):
                return "\(value.text),"
            case let .named(name, value):
                return "\(name) = \(value.text),"
            }
        }
    }
}
