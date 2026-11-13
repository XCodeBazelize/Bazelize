// swift-tools-version: 6.2

import PackageDescription

/// A package that names no `swiftLanguageModes` at all. SwiftPM compiles it in
/// the mode its tools version implies — Swift 6 for a 6.x manifest — which is
/// not what the compiler picks when nobody says.
let package = Package(
    name: "DefaultLanguageMode",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "DefaultLanguageMode", targets: ["DefaultLanguageMode"]),
    ],
    targets: [
        .target(name: "DefaultLanguageMode"),
    ])
