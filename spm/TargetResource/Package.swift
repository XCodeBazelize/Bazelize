// swift-tools-version: 6.0

import PackageDescription

/// The three things a target can do with a resource: copy it as it is, let the
/// platform process it, or compile it into the binary.
let package = Package(
    name: "TargetResource",
    products: [
        .library(name: "TargetResource", targets: ["TargetResource"]),
    ],
    targets: [
        .target(
            name: "TargetResource",
            resources: [
                .copy("Copied"),
                .process("Processed"),
                .embedInCode("Embedded/greeting.txt"),
            ]),
        .testTarget(
            name: "TargetResourceTests",
            dependencies: ["TargetResource"]),
    ])
