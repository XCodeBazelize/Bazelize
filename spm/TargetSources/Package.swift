// swift-tools-version: 6.0

import PackageDescription

/// `sources:`: the target lists the files it compiles, and everything else
/// under its directory is not one of them — including `Loop/self`, a link back
/// to the target's own directory, which a generator that follows links would
/// walk forever and a glob cannot see through at all.
let package = Package(
    name: "TargetSources",
    products: [
        .library(name: "TargetSources", targets: ["TargetSources"]),
    ],
    targets: [
        .target(
            name: "TargetSources",
            /// A file and a directory, to cover both forms.
            sources: ["Compiled.swift", "Kept"]),
        .testTarget(
            name: "TargetSourcesTests",
            dependencies: ["TargetSources"]),
    ])
