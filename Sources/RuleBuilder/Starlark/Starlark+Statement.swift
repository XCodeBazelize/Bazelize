import Foundation

extension Starlark {
    public enum Statement: Text {
        case load(module: String, symbols: [Starlark.LoadSymbol])
        case call(Call)
        
        public var text: String {
            switch self {
            case let .load(module, symbols):
                let renderedSymbols = symbols.map(\.text).joined(separator: ", ")
                if renderedSymbols.isEmpty {
                    return #"load("\#(module)")"#
                }
                return #"load("\#(module)", \#(renderedSymbols))"#
            case let .call(call):
                return call.text
            }
        }
    }
}

extension Starlark {
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
        case positional(Starlark)
        case named(String, Starlark)

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

extension Starlark {
    public struct LoadSymbol: Hashable, Text {
        public let exported: String
        public let local: String?
        
        public init(_ exported: String, as local: String? = nil) {
            self.exported = exported
            self.local = local
        }
        
        public var text: String {
            if let local, local != exported {
                return #"\#(local) = "\#(exported)""#
            }
            return #""\#(exported)""#
        }
    }
}

extension Starlark.LoadSymbol: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}
