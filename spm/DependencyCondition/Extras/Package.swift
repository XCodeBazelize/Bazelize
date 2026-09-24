// swift-tools-version: 6.1

import PackageDescription

/// Depended on only when the trait that asks for it is on, and nothing turns
/// it on.
let package = Package(
    name: "Extras",
    products: [
        .library(name: "Extras", targets: ["Extras"]),
    ],
    targets: [
        .target(name: "Extras"),
    ])
