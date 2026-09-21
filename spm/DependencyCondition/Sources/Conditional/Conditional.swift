import Always
#if canImport(Extras)
import Extras
#endif

public enum Conditional {
    public static let always = Always.value

    /// What the package behind a trait provides, and `nil` when the trait is
    /// off — the dependency is then not part of the build at all.
    public static var extras: Int? {
        #if canImport(Extras)
        return Extras.value
        #else
        return nil
        #endif
    }
}
