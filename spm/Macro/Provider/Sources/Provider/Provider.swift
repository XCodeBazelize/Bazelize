/// Declared here and implemented in this package's macro target: whoever
/// imports this module expands the macro with a plugin built a package away.
@freestanding(expression)
public macro shout(_ value: String) -> String = #externalMacro(
    module: "ProviderMacros",
    type: "ShoutMacro")

public enum Provider {
    /// The same expansion, done inside the package that ships the macro.
    public static var here: String {
        #shout("here")
    }
}
