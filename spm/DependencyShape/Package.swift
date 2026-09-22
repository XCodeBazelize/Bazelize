// swift-tools-version: 6.0

import PackageDescription

/// How a target names what it depends on: a target of its own package by
/// `.target` or by name, a product of another package, a package whose identity
/// is not what its manifest calls it, and a module renamed because two packages
/// ship one of the same name.
let package = Package(
    name: "DependencyShape",
    products: [
        .library(name: "DependencyShape", targets: ["Consumer"]),
    ],
    dependencies: [
        /// The directory is `vendor-kit`, the manifest says `VendorKit`, and the
        /// dependency is written as neither.
        .package(name: "Vendor", path: "vendor-kit"),
        .package(path: "Other"),
    ],
    targets: [
        .target(name: "Local"),
        .target(
            name: "Consumer",
            dependencies: [
                /// A target of this package, named as one.
                .target(name: "Local"),
                /// A target of this package, named by bare string.
                "Helper",
                /// A product of another package.
                .product(name: "VendorCore", package: "Vendor"),
                /// A product whose module is called `Core` too, so it is
                /// renamed here.
                .product(
                    name: "OtherCore",
                    package: "Other",
                    moduleAliases: ["Core": "OtherCore"]),
            ]),
        .target(name: "Helper"),
        .testTarget(
            name: "DependencyShapeTests",
            dependencies: ["Consumer"]),
    ])
