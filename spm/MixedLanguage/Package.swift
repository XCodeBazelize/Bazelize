// swift-tools-version: 6.5

import PackageDescription

/// One target holding C, Objective-C and Swift, which is one module: a
/// consumer imports `Unified` once and reaches both sides of it.
let package = Package(
    name: "MixedLanguage",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "Unified", targets: ["Unified"]),
        .executable(name: "unified-consumer", targets: ["UnifiedConsumer"]),
    ],
    targets: [
        .target(
            name: "Unified",
            /// Not `include`: the umbrella header is where the manifest says.
            publicHeadersPath: "headers",
            cSettings: [
                .headerSearchPath("internal"),
                .define("UNIFIED_C_FLAG"),
                .define("UNIFIED_C_BONUS", to: "1"),
            ],
            swiftSettings: [
                .define("UNIFIED_SWIFT_FLAG"),
            ]),
        .executableTarget(
            name: "UnifiedConsumer",
            dependencies: ["Unified"]),
        .testTarget(
            name: "UnifiedTests",
            dependencies: ["Unified"]),
        /// A test target that is itself mixed: its C file must not be dropped.
        .testTarget(
            name: "UnifiedMixedTests",
            dependencies: ["Unified"]),
    ],
    cLanguageStandard: .c11)
