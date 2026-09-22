// swift-tools-version: 6.1

import PackageDescription

/// Settings conditional on SwiftPM's debug and release build configurations.
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
