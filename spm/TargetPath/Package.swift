// swift-tools-version: 6.0

import PackageDescription

/// Where a target's sources are: named by `path:`, or in one of the
/// directories SwiftPM looks in without being told — `src/` as much as
/// `Sources/`.
let package = Package(
    name: "TargetPath",
    products: [
        .library(name: "TargetPath", targets: ["TargetPath", "Conventional"]),
    ],
    targets: [
        .target(
            name: "TargetPath",
            path: "Code/Library"),
        /// No `path:`: this one is found because `src/<name>` is a place
        /// SwiftPM looks.
        .target(name: "Conventional"),
        .testTarget(
            name: "TargetPathTests",
            dependencies: ["TargetPath", "Conventional"],
            path: "Code/Tests"),
    ])
