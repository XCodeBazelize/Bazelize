// swift-tools-version: 6.0

import PackageDescription

/// What a platform decides, and when it is decided.
///
/// A platform, trait or build configuration is the build's answer, so every
/// one becomes a `select`: the same generated package rule can be compiled
/// through any supported Apple platform transition and gets only that
/// platform's settings and dependencies.
let package = Package(
    name: "Platform",
    platforms: [
        .macOS(.v13),
        .macCatalyst(.v16),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "Platform", targets: ["Platform"]),
    ],
    targets: [
        .target(
            name: "Platform",
            dependencies: [
                .target(name: "IOSOnly", condition: .when(platforms: [.iOS])),
                .target(name: "MacCatalystOnly", condition: .when(platforms: [.macCatalyst])),
                .target(name: "TVOSOnly", condition: .when(platforms: [.tvOS])),
                .target(name: "VisionOSOnly", condition: .when(platforms: [.visionOS])),
                .target(name: "WatchOSOnly", condition: .when(platforms: [.watchOS])),
            ],
            swiftSettings: [
                .define(
                    "APPLE_PLATFORM",
                    .when(platforms: [.macOS, .macCatalyst, .iOS, .tvOS, .watchOS, .visionOS])),
                .define("MACOS_PLATFORM", .when(platforms: [.macOS])),
                .define("MACCATALYST_PLATFORM", .when(platforms: [.macCatalyst])),
                .define("IOS_PLATFORM", .when(platforms: [.iOS])),
                .define(
                    "IOS_DEBUG",
                    .when(platforms: [.iOS], configuration: .debug)),
                .define("TVOS_PLATFORM", .when(platforms: [.tvOS])),
                .define("WATCHOS_PLATFORM", .when(platforms: [.watchOS])),
                .define("VISIONOS_PLATFORM", .when(platforms: [.visionOS])),
                .define("LINUX_PLATFORM", .when(platforms: [.linux])),
                .define("WINDOWS_PLATFORM", .when(platforms: [.windows])),
            ]),
        .target(name: "IOSOnly"),
        .target(name: "MacCatalystOnly"),
        .target(name: "TVOSOnly"),
        .target(name: "VisionOSOnly"),
        .target(name: "WatchOSOnly"),
        .testTarget(
            name: "PlatformTests",
            dependencies: ["Platform"],
            resources: [.process("Fixtures")]),
    ])
