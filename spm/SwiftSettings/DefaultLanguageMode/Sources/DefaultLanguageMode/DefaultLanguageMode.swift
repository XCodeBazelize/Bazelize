/// The manifest declares no language mode, so the tools version decides it:
/// `// swift-tools-version: 6.2` means Swift 6. A build that passed nothing and
/// let the compiler choose lands in Swift 5 and stops here.
#if !swift(>=6.0)
#error("A package declaring no mode compiles in the one its tools version implies")
#endif

public let defaultLanguageMode = 6
