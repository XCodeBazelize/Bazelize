// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "EmptyDependency",
    products: [
        .library(name: "EmptyDependency", targets: ["EmptyDependency"]),
    ],
    traits: [
        .trait(name: "DefaultOn"),
        .default(enabledTraits: ["DefaultOn"]),
    ],
    targets: [
        .target(name: "EmptyDependency"),
    ])
