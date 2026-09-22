// swift-tools-version: 6.0

import PackageDescription

/// A binary target that ships a program rather than a framework: an artifact
/// bundle, holding one build per platform, run by a build tool plugin.
let package = Package(
    name: "ArtifactBundle",
    products: [
        .library(name: "ArtifactBundle", targets: ["ArtifactBundle"]),
    ],
    targets: [
        .binaryTarget(
            name: "GreetTool",
            path: "GreetTool.artifactbundle"),
        .plugin(
            name: "GenerateGreeting",
            capability: .buildTool(),
            dependencies: ["GreetTool"]),
        .target(
            name: "ArtifactBundle",
            plugins: ["GenerateGreeting"]),
        .testTarget(
            name: "ArtifactBundleTests",
            dependencies: ["ArtifactBundle"]),
    ])
