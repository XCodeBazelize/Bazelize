// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "TraitGraph",
    products: [
        .library(name: "TraitGraph", targets: ["TraitGraph"]),
    ],
    traits: [
        .trait(name: "Leaf"),
        .trait(name: "Middle", enabledTraits: ["Leaf"]),
        .trait(name: "Top", enabledTraits: ["Middle"]),
        .trait(name: "Alternative"),
        .default(enabledTraits: ["Top"]),
    ],
    dependencies: [
        .package(path: "DefaultDependency", traits: [.defaults]),
        .package(path: "EmptyDependency", traits: []),
        .package(path: "ExplicitDependency", traits: ["Top"]),
    ],
    targets: [
        .target(
            name: "TraitGraph",
            dependencies: [
                .product(name: "DefaultDependency", package: "DefaultDependency"),
                .product(name: "EmptyDependency", package: "EmptyDependency"),
                .product(name: "ExplicitDependency", package: "ExplicitDependency"),
            ],
            swiftSettings: [
                .define("ANY_BRANCH", .when(traits: ["Middle", "Alternative"])),
            ]),
        .executableTarget(
            name: "TraitProbe",
            dependencies: ["TraitGraph"]),
        .testTarget(
            name: "TraitGraphTests",
            dependencies: ["TraitGraph"]),
    ])
