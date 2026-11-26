@resultBuilder
public enum ArgumentBuilder {
    public typealias Target = Starlark.Statement.Argument

    public static func buildExpression(_ expression: Target) -> [Target] {
        [expression]
    }

    /// An attribute given nil is an attribute left out of the call.
    public static func buildExpression(_ expression: Target?) -> [Target] {
        expression.map { [$0] } ?? []
    }

    public static func buildExpression(_ expression: Target.Visibility) -> [Target] {
        [expression.argument]
    }

    public static func buildBlock(_ components: Target...) -> [Target] {
        components
    }

    public static func buildBlock(_ components: [Target]...) -> [Target] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [Target]?) -> [Target] {
        component ?? []
    }

    public static func buildEither(first component: [Target]) -> [Target] {
        component
    }

    public static func buildEither(second component: [Target]) -> [Target] {
        component
    }
}
