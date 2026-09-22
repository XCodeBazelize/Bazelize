// swift-tools-version: 6.0

import PackageDescription

/// The directory is `vendor-kit`, which is the identity SwiftPM files this
/// package under; the name here is what a manifest that depends on it may use
/// instead.
let package = Package(
    name: "VendorKit",
    products: [
        .library(name: "VendorCore", targets: ["VendorCore"]),
    ],
    targets: [
        .target(name: "VendorCore"),
    ])
