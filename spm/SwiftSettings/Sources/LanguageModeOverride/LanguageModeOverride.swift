/// The package compiles in Swift 5; this target said Swift 6, and a target's
/// own mode is the one it gets.
#if !swift(>=6.0)
#error("The target's own language mode must win over the package's")
#endif

public let languageModeOverride = 6
