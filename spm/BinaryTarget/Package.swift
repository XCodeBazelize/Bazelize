// swift-tools-version: 6.0

import PackageDescription

/// A local zipped XCFramework consumed through a Swift library target.
let package = Package(
    name: "BinaryTarget",
    products: [
        .library(name: "BinaryTarget", targets: ["BinaryTarget"]),
    ],
    targets: [
        .binaryTarget(
            name: "LocalBinary",
            path: "LocalBinary.xcframework.zip"),
        .target(
            name: "BinaryTarget",
            dependencies: ["LocalBinary"]),
        .testTarget(
            name: "BinaryTargetTests",
            dependencies: ["BinaryTarget"]),
    ])
