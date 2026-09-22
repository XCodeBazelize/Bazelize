// swift-tools-version: 6.0

import PackageDescription

/// `.embedInCode`: the one resource rule that produces no bundle at all — the
/// file's bytes become a generated source the target compiles.
///
/// Its own package because the default build system in this toolchain
/// generates nothing for it, so this is the only fixture whose SwiftPM side
/// needs `--build-system native`.
let package = Package(
    name: "TargetEmbed",
    products: [
        .library(name: "TargetEmbed", targets: ["TargetEmbed"]),
    ],
    targets: [
        .target(
            name: "TargetEmbed",
            resources: [
                .embedInCode("Embedded/greeting.txt"),
            ]),
        .testTarget(
            name: "TargetEmbedTests",
            dependencies: ["TargetEmbed"]),
    ])
