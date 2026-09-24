// swift-tools-version: 6.0

import PackageDescription

/// A binary target that ships a program and is fetched rather than found:
/// SwiftPM downloads the archive, checks it against the checksum, and unpacks
/// it into the workspace's artifact directory — which is not where a local one
/// is, and is the only place this one can be looked for.
let package = Package(
    name: "RemoteArtifactBundle",
    products: [
        .library(name: "RemoteArtifactBundle", targets: ["RemoteArtifactBundle"]),
    ],
    targets: [
        /// Named after the artifact the bundle holds: that is what a plugin
        /// asks for it by.
        .binaryTarget(
            name: "periphery",
            url: "https://github.com/peripheryapp/periphery/releases/download/3.8.0/periphery-3.8.0.artifactbundle.zip",
            checksum: "a9c7bfb1483dde1f4b660bc64183161fde3b519b7392add51ec8fe8b846cf494"),
        .plugin(
            name: "RecordVersion",
            capability: .buildTool(),
            dependencies: ["periphery"]),
        .target(
            name: "RemoteArtifactBundle",
            plugins: ["RecordVersion"]),
        .testTarget(
            name: "RemoteArtifactBundleTests",
            dependencies: ["RemoteArtifactBundle"]),
    ])
