// swift-tools-version: 6.0

import PackageDescription

/// What a target can do with a resource: copy it as it is, let the platform
/// process it, or compile it into the binary — plus the localized and
/// platform-compiled kinds, and the directories SwiftPM ignores.
let package = Package(
    name: "TargetResource",
    defaultLocalization: "en",
    products: [
        .library(name: "TargetResource", targets: ["TargetResource"]),
    ],
    targets: [
        .target(
            name: "TargetResource",
            resources: [
                .copy("Copied"),
                /// A single file rather than a directory: it lands at the
                /// bundle's root under its own name.
                .copy("single.txt"),
                .process("Processed"),
                .process("Localized", localization: .default),
                .embedInCode("Embedded/greeting.txt"),
                /// Kinds the platform compiles rather than copies.
                .process("Assets.xcassets"),
                .process("Panel.xib"),
                .process("Shader.metal"),
                .process("Catalog.xcstrings"),
            ]),
        /// A test target has resources the same way any other target does, and
        /// its own bundle to reach them through.
        .testTarget(
            name: "TargetResourceTests",
            dependencies: ["TargetResource"],
            resources: [
                .process("Fixtures"),
            ]),
    ])
