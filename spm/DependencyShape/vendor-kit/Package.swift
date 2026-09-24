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
        /// A package this one depends on has resources like any other, and a
        /// bundle of its own to reach them through — which the package using
        /// it never sees.
        .target(
            name: "VendorCore",
            resources: [
                .process("Resources"),
            ]),
    ])
