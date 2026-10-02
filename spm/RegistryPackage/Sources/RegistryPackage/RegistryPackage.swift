import RegistryDependency

/// What the dependency answers, through the package that depends on it: a
/// target that compiles this has the registry package's module.
public enum RegistryPackage {
    public static var greeting: String {
        RegistryDependency.greeting
    }
}
