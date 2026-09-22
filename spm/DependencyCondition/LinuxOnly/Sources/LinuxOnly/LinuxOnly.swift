/// A package nothing here builds: what proves it is the target that would have
/// linked it, which fails to compile if this module ever became importable.
public enum LinuxOnly {
    public static let value = 2
}
