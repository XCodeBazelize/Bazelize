// swift-tools-version: 6.0

import PackageDescription

/// Its product is called `VendorCore` too: a product name belongs to the
/// package that ships it, so two packages can name one the same and whoever
/// uses both says which package it means.
let package = Package(
    name: "Alt",
    products: [
        .library(name: "VendorCore", targets: ["AltCore"]),
    ],
    targets: [
        .target(name: "AltCore"),
    ])
