// swift-tools-version: 6.0

import PackageDescription

/// What a platform decides, and when it is decided.
///
/// A platform, trait or build configuration is the build's answer, so every
/// one becomes a `select`: the same generated package rule can be compiled
/// through a macOS or iOS transition and gets only that platform's settings
/// and dependencies.
let package = Package(
    name: "Platform",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        .library(name: "Platform", targets: ["Platform"]),
    ],
    targets: [
        .target(
            name: "Platform",
            dependencies: [
                .target(name: "IOSOnly", condition: .when(platforms: [.iOS])),
            ],
            swiftSettings: [
                .define("APPLE_PLATFORM", .when(platforms: [.macOS, .iOS])),
                .define("MACOS_PLATFORM", .when(platforms: [.macOS])),
                .define("IOS_PLATFORM", .when(platforms: [.iOS])),
                .define(
                    "IOS_DEBUG",
                    .when(platforms: [.iOS], configuration: .debug)),
                .define("LINUX_PLATFORM", .when(platforms: [.linux])),
                .define("WINDOWS_PLATFORM", .when(platforms: [.windows])),
            ]),
        .target(name: "IOSOnly"),
        .testTarget(
            name: "PlatformTests",
            dependencies: ["Platform"]),
    ])
