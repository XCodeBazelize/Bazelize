// swift-tools-version: 6.0

import PackageDescription

/// A build tool plugin that belongs to another package: the target names the
/// plugin and the package it comes from, and neither the plugin nor the tool it
/// runs is anything this package builds.
let package = Package(
    name: "PluginDependency",
    products: [
        .library(name: "PluginDependency", targets: ["PluginDependency"]),
    ],
    dependencies: [
        .package(path: "Stamping"),
    ],
    targets: [
        .target(
            name: "PluginDependency",
            plugins: [
                .plugin(name: "Stamp", package: "Stamping"),
            ]),
        .testTarget(
            name: "PluginDependencyTests",
            dependencies: ["PluginDependency"]),
    ])
