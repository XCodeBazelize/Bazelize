import Provider

/// Expanded by this package's own macro target.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(
    module: "StringifyMacros",
    type: "StringifyMacro")

public enum Stringify {
    /// `(2, "1 + 1")`, which only exists if the compiler loaded the macro.
    public static var onePlusOne: (Int, String) {
        #stringify(1 + 1)
    }

    /// Expanded by the macro of another package: the plugin the compiler loads
    /// for this is built a package away, and reached through that package's
    /// product.
    public static var shouted: String {
        #shout("across")
    }

    /// The same macro, expanded inside the package that ships it.
    public static var shoutedThere: String {
        Provider.here
    }
}
