// swift-tools-version: 6.0

import PackageDescription

/// `path:`: the target is not under `Sources/<name>`.
let package = Package(
    name: "TargetPath",
    products: [
        .library(name: "TargetPath", targets: ["TargetPath"]),
    ],
    targets: [
        .target(
            name: "TargetPath",
            path: "Code/Library"),
        .testTarget(
            name: "TargetPathTests",
            dependencies: ["TargetPath"],
            path: "Code/Tests"),
    ])
