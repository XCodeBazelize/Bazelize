// swift-tools-version: 6.0

import PackageDescription

/// The package next door, which ships a plugin as a product and the tool that
/// plugin runs.
let package = Package(
    name: "Stamping",
    products: [
        .plugin(name: "Stamp", targets: ["Stamp"]),
        .executable(name: "StampTool", targets: ["StampTool"]),
    ],
    targets: [
        .plugin(
            name: "Stamp",
            capability: .buildTool(),
            dependencies: ["StampTool"]),
        .executableTarget(name: "StampTool"),
    ])
