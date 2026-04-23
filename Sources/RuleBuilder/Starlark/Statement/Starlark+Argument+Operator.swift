import Foundation

infix operator => : AssignmentPrecedence
extension String {
    private static func named(_ propertyName: String, _ value: Starlark.Value) -> Starlark.Statement.Argument {
        .named(propertyName, value)
    }

    public static func =>(propertyName: String, bool: Bool) -> Starlark.Statement.Argument {
        named(propertyName, .bool(bool))
    }

    public static func =>(propertyName: String, int: Int) -> Starlark.Statement.Argument {
        named(propertyName, .int(int))
    }

    public static func =>(propertyName: String, label: Starlark.Label) -> Starlark.Statement.Argument {
        named(propertyName, .label(label))
    }

    public static func =>(propertyName: String, label: String?) -> Starlark.Statement.Argument {
        named(propertyName, .init(label) ?? None)
    }

    public static func =>(propertyName: String, dictionary: [String: String]) -> Starlark.Statement.Argument {
        named(propertyName, .init(dictionary) ?? None)
    }

    public static func =>(propertyName: String, starlark: Starlark.Value) -> Starlark.Statement.Argument {
        named(propertyName, starlark)
    }

    public static func =>(propertyName: String, select: Starlark.Select<String>) -> Starlark.Statement.Argument {
        named(propertyName, select.starlark)
    }

    public static func =>(propertyName: String, select: Starlark.Select<String?>) -> Starlark.Statement.Argument {
        named(propertyName, select.starlark)
    }

    public static func =>(propertyName: String, select: Starlark.Select<[String]>) -> Starlark.Statement.Argument {
        named(propertyName, select.starlark)
    }

    public static func =>(propertyName: String, select: Starlark.Select<Bool>) -> Starlark.Statement.Argument {
        named(propertyName, select.starlark)
    }
}


extension String {
    public static func =>(propertyName: String, labels: [Starlark.Label]) -> Starlark.Statement.Argument {
        named(propertyName, labels.map(Starlark.Value.label).starlark)
    }

    public static func =>(propertyName: String, labels: [String]) -> Starlark.Statement.Argument {
        named(propertyName, labels.map(Starlark.Value.string).starlark)
    }

    public static func =>(propertyName: String, labels: [String]?) -> Starlark.Statement.Argument {
        named(propertyName, .init(labels) ?? None)
    }

    public static func =>(propertyName: String, labels: [String?]) -> Starlark.Statement.Argument {
        named(propertyName, .init(labels) ?? None)
    }

    public static func =>(propertyName: String, ints: [Int]) -> Starlark.Statement.Argument {
        named(propertyName, ints.map(Starlark.Value.int).starlark)
    }

    public static func =>(propertyName: String, bools: [Bool]) -> Starlark.Statement.Argument {
        named(propertyName, bools.map(Starlark.Value.bool).starlark)
    }

    public static func =>(propertyName: String, starlarks: [Starlark.Value]) -> Starlark.Statement.Argument {
        named(propertyName, starlarks.starlark)
    }
}

extension String {
    public static func =>(propertyName: String, @StarlarkBuilder builder: () -> Starlark.Value) -> Starlark.Statement.Argument {
        .named(propertyName, builder: builder)
    }
}
