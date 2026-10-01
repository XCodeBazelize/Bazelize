// swift-tools-version: 6.0

import PackageDescription

/// A package whose dependency is named by registry identity rather than by URL
/// or path.
///
/// Nothing here contacts a registry: `Registry/` holds what one would have
/// served, and whoever generates this fixture unpacks it where SwiftPM unpacks
/// a registry download. See `README.md` beside this file.
let package = Package(
    name: "RegistryPackage",
    products: [
        .library(name: "RegistryPackage", targets: ["RegistryPackage"]),
    ],
    dependencies: [
        .package(id: "bazelize.registry-dependency", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "RegistryPackage",
            dependencies: [
                .product(name: "RegistryDependency", package: "bazelize.registry-dependency"),
            ]),
        .testTarget(
            name: "RegistryPackageTests",
            dependencies: ["RegistryPackage"]),
    ])
