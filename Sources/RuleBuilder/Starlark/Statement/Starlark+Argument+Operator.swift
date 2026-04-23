import Foundation

infix operator => : AssignmentPrecedence
extension String {
    public static func =>(propertyName: String, bool: Bool) -> Starlark.Statement.Argument {
        .named(propertyName, .bool(bool))
    }

    public static func =>(propertyName: String, label: String?) -> Starlark.Statement.Argument {
        .named(propertyName, .init(label) ?? None)
    }

    public static func =>(propertyName: String, dictionary: [String: String]) -> Starlark.Statement.Argument {
        .named(propertyName, .init(dictionary) ?? None)
    }

    public static func =>(propertyName: String, starlark: Starlark.Value) -> Starlark.Statement.Argument {
        .named(propertyName, starlark)
    }
}

extension String {
    public static func =>(propertyName: String, @StarlarkBuilder builder: () -> Starlark.Value) -> Starlark.Statement.Argument {
        .named(propertyName, builder: builder)
    }

    public static func =>(propertyName: String, labels: [String]) -> Starlark.Statement.Argument {
        .named(propertyName) {
            labels
        }
    }

    public static func =>(propertyName: String, labels: [String]?) -> Starlark.Statement.Argument {
        .named(propertyName) {
            labels
        }
    }

    public static func =>(propertyName: String, starlarks: [Starlark.Value]) -> Starlark.Statement.Argument {
        .named(propertyName) {
            starlarks
        }
    }
}
