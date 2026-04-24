extension Starlark {
    public struct Comment: Sendable, Text {
        public let value: String

        public init(_ value: String) {
            self.value = value
        }

        public var text: String {
            value.comment
        }
    }
}
