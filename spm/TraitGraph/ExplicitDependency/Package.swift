// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "ExplicitDependency",
    products: [
        .library(name: "ExplicitDependency", targets: ["ExplicitDependency"]),
    ],
    traits: [
        .trait(name: "Leaf"),
        .trait(name: "Middle", enabledTraits: ["Leaf"]),
        .trait(name: "Top", enabledTraits: ["Middle"]),
        .default(enabledTraits: ["Leaf"]),
    ],
    targets: [
        .target(name: "ExplicitDependency"),
    ])
