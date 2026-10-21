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
            dependencies: [
                "ProbeSupport",
            ],
            resources: [
                .copy("Copied"),
                .process("Processed"),
                .process("Assets.xcassets"),
            ]),
        /// A library's resources reach a program the same way: not through an
        /// Apple bundler, which a command line tool does not have.
        .target(
            name: "ProbeSupport",
            resources: [
                .process("support.txt"),
            ]),
    ])
