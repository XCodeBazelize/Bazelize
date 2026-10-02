public enum Dependency {
    /// On only because the package that depends on this one asked for the
    /// trait by name: it is not one of this package's defaults. The trait is
    /// the condition, nothing had to declare a define for it.
    public static var extra: Bool {
        #if Extra
        return true
        #else
        return false
        #endif
    }
}
