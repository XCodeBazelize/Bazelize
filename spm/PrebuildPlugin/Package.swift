// swift-tools-version: 6.0

import PackageDescription

/// The other kind of build tool command: a prebuild command runs before the
/// build rather than as part of it, and what it writes is not known until it
/// has — the plugin names a directory, not files.
let package = Package(
    name: "PrebuildPlugin",
    products: [
        .library(name: "PrebuildPlugin", targets: ["PrebuildPlugin"]),
    ],
    targets: [
        .plugin(
            name: "GeneratePrebuild",
            capability: .buildTool()),
        .target(
            name: "PrebuildPlugin",
            plugins: ["GeneratePrebuild"]),
        .testTarget(
            name: "PrebuildPluginTests",
            dependencies: ["PrebuildPlugin"]),
    ])
