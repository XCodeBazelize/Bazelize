// swift-tools-version: 6.0

import PackageDescription

/// Consumes grouped and target-name-colliding products from a local package.
let package = Package(
    name: "ProductShapes",
    products: [
        .library(name: "ProductShapes", targets: ["ProductShapes"]),
    ],
    dependencies: [
        .package(path: "Products"),
    ],
    targets: [
        .target(
            name: "ProductShapes",
            dependencies: [
                .product(name: "Combined", package: "Products"),
                .product(name: "First", package: "Products"),
            ]),
        .testTarget(
            name: "ProductShapesTests",
            dependencies: ["ProductShapes"]),
    ])
