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
}
