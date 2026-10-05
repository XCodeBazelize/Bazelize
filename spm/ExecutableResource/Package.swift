// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ExecutableResource",
    products: [
        .executable(name: "resource-probe", targets: ["ResourceProbe"]),
    ],
    targets: [
        .executableTarget(
            name: "ResourceProbe",
            resources: [
                .copy("Copied"),
                .process("Processed"),
                .process("Assets.xcassets"),
            ]),
    ])
