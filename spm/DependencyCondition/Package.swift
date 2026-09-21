// swift-tools-version: 6.1

import PackageDescription

/// A dependency can be conditional: on the platform being built, or on a trait
/// being on. What the condition excludes must not be built at all.
///
/// The conditional ones are packages of their own because a target of the
/// package being built is compiled whether anything depends on it or not — only
/// a dependency is left alone.
let package = Package(
    name: "DependencyCondition",
    products: [
        .library(name: "Conditional", targets: ["Conditional"]),
    ],
    traits: [
        .trait(name: "Extras"),
    ],
    dependencies: [
        .package(path: "LinuxOnly"),
        .package(path: "Extras"),
    ],
    targets: [
        .target(
            name: "Conditional",
            dependencies: [
                "Always",
                .product(name: "LinuxOnly", package: "LinuxOnly", condition: .when(platforms: [.linux])),
                .product(name: "Extras", package: "Extras", condition: .when(traits: ["Extras"])),
            ]),
        .target(name: "Always"),
        .testTarget(
            name: "ConditionalTests",
            dependencies: ["Conditional"]),
    ])
