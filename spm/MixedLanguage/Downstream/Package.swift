// swift-tools-version: 6.5

import PackageDescription

/// Another package that depends on the `Unified` product: what a mixed module
/// offers has to reach targets outside its own package too.
let package = Package(
    name: "Downstream",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: ".."),
    ],
    targets: [
        /// Objective-C only: `@import Unified` reaches both halves.
        .target(
            name: "DownstreamBridge",
            dependencies: [.product(name: "Unified", package: "MixedLanguage")]),
        .executableTarget(
            name: "downstream-consumer",
            dependencies: [
                "DownstreamBridge",
                .product(name: "Unified", package: "MixedLanguage"),
            ]),
    ])
