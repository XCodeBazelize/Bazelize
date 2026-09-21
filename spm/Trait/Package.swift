// swift-tools-version: 6.1

import PackageDescription

/// Traits: a package's own build-time options. Three things decide which ones
/// are on — the package's defaults, what a dependent asks for by name, and
/// nothing else — and a build setting can be conditional on one.
let package = Package(
    name: "Trait",
    products: [
        .library(name: "Trait", targets: ["Trait"]),
    ],
    traits: [
        .trait(name: "Fast"),
        .trait(name: "Slow"),
        .default(enabledTraits: ["Fast"]),
    ],
    dependencies: [
        .package(path: "Dependency", traits: ["Extra"]),
    ],
    targets: [
        .target(
            name: "Trait",
            dependencies: [
                .product(name: "Dependency", package: "Dependency"),
            ],
            swiftSettings: [
                .define("FAST", .when(traits: ["Fast"])),
                .define("SLOW", .when(traits: ["Slow"])),
            ]),
        .testTarget(
            name: "TraitTests",
            dependencies: ["Trait"]),
    ])
