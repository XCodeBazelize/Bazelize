// swift-tools-version: 6.1

import PackageDescription

/// Traits: a package's own build-time options. A trait that is on is a
/// compilation condition of that package's own sources — `#if Fast` — and can
/// carry settings and dependencies of its own.
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
            ]),
        .testTarget(
            name: "TraitTests",
            dependencies: ["Trait"]),
    ])
