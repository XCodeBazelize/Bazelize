import Dependency

public enum Trait {
    /// Which of this package's traits the build enabled. `Fast` is the default
    /// one, so a build that asked for nothing still gets it; `Slow` is not.
    public static var enabled: [String] {
        var traits: [String] = []
        #if FAST
        traits.append("Fast")
        #endif
        #if SLOW
        traits.append("Slow")
        #endif
        return traits
    }

    /// Whether the trait this package asked the package next door for is on.
    public static var dependencyExtra: Bool {
        Dependency.extra
    }
}
