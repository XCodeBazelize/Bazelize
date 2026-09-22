// swift-tools-version: 6.0

import PackageDescription

/// System-library targets whose module maps supply their headers and linker
/// input: one that links a library, one that links a framework.
let package = Package(
    name: "SystemLibrary",
    products: [
        .library(name: "SystemLibrary", targets: ["SystemLibrary"]),
    ],
    targets: [
        .systemLibrary(
            name: "CZlib",
            pkgConfig: "zlib",
            providers: [
                .brew(["zlib"]),
                .apt(["zlib1g-dev"]),
            ]),
        /// `link framework` rather than `link`: the other half of what a module
        /// map can ask the linker for.
        .systemLibrary(name: "CSecurity"),
        .target(
            name: "SystemLibrary",
            dependencies: ["CZlib", "CSecurity"]),
        .testTarget(
            name: "SystemLibraryTests",
            dependencies: ["SystemLibrary"]),
    ])
