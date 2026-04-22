@resultBuilder
public enum ArgumentBuilder {
    public typealias Target = Starlark.Statement.Argument

    public static func buildExpression(_ expression: String) -> Target {
        .positional(.string(expression))
    }

    public static func buildExpression(_ expression: Target) -> Target {
        expression
    }

    public static func buildBlock(_ components: Target...) -> [Target] {
        components
    }

    public static func buildBlock(_ components: [Target]...) -> [Target] {
        components.flatMap { $0 }
    }
}
