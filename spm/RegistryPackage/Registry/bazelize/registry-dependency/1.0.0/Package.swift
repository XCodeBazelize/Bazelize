// swift-tools-version: 6.0

import PackageDescription

/// What a registry would have served for `bazelize.registry-dependency` at
/// 1.0.0: an ordinary package, which is all a registry download ever is once
/// SwiftPM has unpacked it.
let package = Package(
    name: "RegistryDependency",
    products: [
        .library(name: "RegistryDependency", targets: ["RegistryDependency"]),
    ],
    targets: [
        .target(name: "RegistryDependency"),
    ])
