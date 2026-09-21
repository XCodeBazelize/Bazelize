import Dependency

public enum Trait {
    /// Which of this package's traits the build has on. A trait is a
    /// compilation condition named after itself, which is what SwiftPM
    /// compiles the package with.
    public static var enabled: [String] {
        var traits: [String] = []
        #if Fast
        traits.append("Fast")
        #endif
        #if Slow
        traits.append("Slow")
        #endif
        return traits
    }

    /// The setting that trait carries, which is not the same thing as the
    /// trait being on.
    public static var slowExtra: Bool {
        #if SLOW_EXTRA
        return true
        #else
        return false
        #endif
    }

    /// Whether the trait this package asked the package next door for is on.
    public static var dependencyExtra: Bool {
        Dependency.extra
    }
}
