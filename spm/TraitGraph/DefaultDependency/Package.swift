// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "DefaultDependency",
    products: [
        .library(name: "DefaultDependency", targets: ["DefaultDependency"]),
    ],
    traits: [
        .trait(name: "DefaultOn"),
        .default(enabledTraits: ["DefaultOn"]),
    ],
    targets: [
        .target(name: "DefaultDependency"),
    ])
