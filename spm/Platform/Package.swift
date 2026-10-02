// swift-tools-version: 6.0

import PackageDescription

/// What a platform decides, and when it is decided.
///
/// A trait or a build configuration is the build's answer, so it becomes a
/// `select`. A platform is not: a package rule is compiled for whatever pulls
/// it in, so a setting conditional on a platform nothing here builds is
/// dropped while the rules are written, and one conditional on a platform an
/// Apple toolchain does build is kept.
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
            swiftSettings: [
                .define("APPLE_PLATFORM", .when(platforms: [.macOS, .iOS])),
                .define("MACOS_PLATFORM", .when(platforms: [.macOS])),
                .define("LINUX_PLATFORM", .when(platforms: [.linux])),
                .define("WINDOWS_PLATFORM", .when(platforms: [.windows])),
            ]),
        .testTarget(
            name: "PlatformTests",
            dependencies: ["Platform"]),
    ])
