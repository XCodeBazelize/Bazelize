import Foundation

extension Starlark.Statement {
    public struct Load: Text {
        public let module: String
        public let symbols: [Starlark.Statement.LoadSymbol]

        public var statemenet: Starlark.Statement {
            .load(self)
        }

        public init(module: String, symbols: [Starlark.Statement.LoadSymbol] = []) {
            self.module = module
            self.symbols = symbols
        }

        public var text: String {
            let renderedSymbols = symbols.map(\.text).joined(separator: ", ")
            if renderedSymbols.isEmpty {
                return #"load("\#(module)")"#
            }
            return #"load("\#(module)", \#(renderedSymbols))"#
        }
    }

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

// MARK: - Starlark.Statement.LoadSymbol + ExpressibleByStringLiteral

extension Starlark.Statement.LoadSymbol: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}


// MARK: - Starlark.Statement.Load + Comparable

extension Starlark.Statement.Load: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.module < rhs.module
    }
}
