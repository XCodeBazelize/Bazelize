// swift-tools-version: 6.0

import PackageDescription

/// Its module is called `Core`, which is also what another package in the graph
/// calls one of its own: whoever uses both has to rename one.
let package = Package(
    name: "Other",
    products: [
        .library(name: "OtherCore", targets: ["Core"]),
    ],
    targets: [
        .target(name: "Core"),
    ])
