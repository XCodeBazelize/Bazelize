// swift-tools-version: 6.1

import PackageDescription

/// The package next door, whose traits are turned on by whoever depends on it.
let package = Package(
    name: "Dependency",
    products: [
        .library(name: "Dependency", targets: ["Dependency"]),
    ],
    traits: [
        .trait(name: "Extra"),
    ],
    targets: [
        .target(
            name: "Dependency",
            swiftSettings: [
                .define("EXTRA", .when(traits: ["Extra"])),
            ]),
    ])
