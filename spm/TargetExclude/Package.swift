// swift-tools-version: 6.0

import PackageDescription

/// `exclude:`: everything under the target's directory is compiled except what
/// the manifest names.
let package = Package(
    name: "TargetExclude",
    products: [
        .library(name: "TargetExclude", targets: ["TargetExclude"]),
    ],
    targets: [
        .target(
            name: "TargetExclude",
            /// A directory and a single file, to cover both forms.
            exclude: ["Excluded", "Notes.swift"]),
        .testTarget(
            name: "TargetExcludeTests",
            dependencies: ["TargetExclude"]),
    ])
