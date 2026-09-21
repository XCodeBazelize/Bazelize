public enum Dependency {
    /// On only because the package that depends on this one asked for the trait
    /// by name: it is not one of this package's defaults.
    public static var extra: Bool {
        #if EXTRA
        return true
        #else
        return false
        #endif
    }
}
