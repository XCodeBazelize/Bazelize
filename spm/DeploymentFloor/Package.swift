// swift-tools-version: 6.0

import PackageDescription

/// The deployment floor the package graph declares. SwiftPM compiles every
/// target of a graph at the highest version any package in it asks for, and a
/// back-port that is `obsoleted:` above that floor is reachable only there —
/// which is what makes the floor observable rather than a number in a file.
let package = Package(
    name: "DeploymentFloor",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "FloorProbe", targets: ["FloorProbe"]),
    ],
    targets: [
        .target(name: "FloorProbe"),
        .testTarget(
            name: "DeploymentFloorTests",
            dependencies: ["FloorProbe"]),
    ])
