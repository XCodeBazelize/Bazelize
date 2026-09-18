/// Expanded by the package's own macro target.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(
    module: "Local1Macros",
    type: "StringifyMacro")

// MARK: - LocalTarget1

public struct LocalTarget1 {
    public private(set) var text = "Hello, World!"

    public init() { }

    /// `("1 + 1", 2)` without writing either out twice.
    public static var stringified: (Int, String) {
        #stringify(1 + 1)
    }

    /// What the package's build tool plugin generated.
    public static var generated: Int {
        Local1Generated.value
    }
}
