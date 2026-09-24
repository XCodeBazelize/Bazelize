// swift-tools-version: 6.0

import PackageDescription

/// System-library targets: one whose module map links a library, one whose
/// module map links a framework, and one whose headers only `pkg-config` knows
/// the way to — which is why `PKG_CONFIG_PATH` has to name `vendor/pkgconfig`
/// for this package to build at all.
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
        /// Nothing in the package says where this one's header is: `pkg-config`
        /// does, and its `Cflags` are the whole reason the module compiles.
        .systemLibrary(
            name: "CGreet",
            pkgConfig: "bazelize-greet",
            providers: [
                .brew(["bazelize-greet"]),
                .apt(["bazelize-greet-dev"]),
            ]),
        .target(
            name: "SystemLibrary",
            dependencies: ["CZlib", "CSecurity", "CGreet"]),
        .testTarget(
            name: "SystemLibraryTests",
            dependencies: ["SystemLibrary"]),
    ])
