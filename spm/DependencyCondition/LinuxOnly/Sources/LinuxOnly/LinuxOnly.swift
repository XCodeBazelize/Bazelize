#if !os(Linux)
#error("This package is a Linux-only dependency, so building it here is the bug this package is here to catch.")
#endif

public enum LinuxOnly {
    public static let value = 2
}
