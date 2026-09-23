// swift-tools-version: 6.0

import PackageDescription

/// `.embedInCode`: the one resource rule that produces no bundle at all — the
/// file's bytes become a generated source the target compiles.
///
/// Its own package because the two build systems SwiftPM ships disagreed about
/// it — `swiftbuild` generated nothing for it on the toolchain this fixture was
/// written against — so its SwiftPM side is run with `--build-system native`.
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
