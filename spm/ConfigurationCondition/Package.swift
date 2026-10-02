// swift-tools-version: 6.1

import PackageDescription

/// Settings conditional on SwiftPM's debug and release build configurations.
///
/// Its sources are in `Sources` itself rather than a directory of the target's
/// own, which SwiftPM allows when no other target could claim them — a package
/// with one target of that kind.
let configurationSettings: [SwiftSetting] = [
    .define("DEBUG_ONLY", .when(configuration: .debug)),
    .define("RELEASE_ONLY", .when(configuration: .release)),
]

let package = Package(
    name: "ConfigurationCondition",
    products: [
        .library(name: "ConfigurationCondition", targets: ["ConfigurationCondition"]),
    ],
    targets: [
        .target(
            name: "ConfigurationCondition",
            swiftSettings: configurationSettings),
        .testTarget(
            name: "ConfigurationConditionTests",
            dependencies: ["ConfigurationCondition"],
            swiftSettings: configurationSettings),
    ])
