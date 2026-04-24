import Foundation

// MARK: - Starlark.Label

extension Starlark {
    public struct Label: Sendable, Hashable, Text {
        public let value: String

        public init(_ value: String) {
            self.value = value
        }

        public static let `default`: Self = .init("//conditions:default")

        public static func config(_ name: String) -> Self {
            .init("//:\(name)")
        }

        public static func named(_ value: String) -> Self {
            .init(value)
        }

        public var text: String {
            #""\#(value)""#
        }
    }
}

// MARK: - Starlark.Label + ExpressibleByStringLiteral

extension Starlark.Label: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}
