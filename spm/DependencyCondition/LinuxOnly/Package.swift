// swift-tools-version: 6.1

import PackageDescription

/// Depended on only when the platform being built is Linux.
let package = Package(
    name: "LinuxOnly",
    products: [
        .library(name: "LinuxOnly", targets: ["LinuxOnly"]),
    ],
    targets: [
        .target(name: "LinuxOnly"),
    ])
