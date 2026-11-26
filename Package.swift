// swift-tools-version:6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Bazelize",
    /// `Xcode.Target` is noncopyable and kept in swift-collections' `UniqueArray`,
    /// which needs `libswiftCompatibilitySpan`. macOS ships it from 26 on; an older
    /// floor makes the standalone binary load a library only an app bundle carries.
    platforms: [
        .macOS(.v26),
    ],
    products: [
        .executable(name: "bazelize", targets: ["Bazelize"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.

        .package(url: "https://github.com/tuist/XcodeProj", from: "9.17.8"),
        .package(url: "https://github.com/jpsim/Yams", from: "6.2.2"),
        .package(url: "https://github.com/kylef/PathKit", from: "1.0.1"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.7.5"),

        .package(url: "https://github.com/swiftlang/swift-subprocess", from: "1.0.0"),

        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.8.2"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "Bazelize",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "PathKit",
                "BazelizeKit",
                "Xcode",
                "XcodeLoader",
            ]),
        .executableTarget(
            name: "RepoEnumGenerator",
            dependencies: [
                "RepoEnumCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]),

        .target(
            name: "BazelRules",
            dependencies: [
                "Starlark",
            ]),
        .testTarget(
            name: "BazelRulesTests",
            dependencies: ["BazelRules"]),
        .target(
            name: "Starlark",
            dependencies: [
                "Util",
            ]),
        .testTarget(
            name: "StarlarkTests",
            dependencies: ["Starlark"]),

        .target(
            name: "BazelizeKit",
            dependencies: [
                "Yams",
                "PathKit",

                "BazelRules",
                "Xcode",
                "XcodeLoader",
                "Util",
                "Starlark",
                "PluginLoader",

                .product(name: "Subprocess", package: "swift-subprocess"),
            ]),
        .testTarget(
            name: "BazelizeKitTests",
            dependencies: ["BazelizeKit", "PathKit"]),
        .target(
            name: "RepoEnumCore",
            dependencies: [
                "Yams",
            ]),

        .target(
            name: "Util",
            dependencies: [
                "Yams",
                "PathKit",
            ]),
        .testTarget(
            name: "UtilTests",
            dependencies: ["Util"]),

        .target(
            name: "Xcode",
            dependencies: [
                "PathKit",

                .product(name: "BasicContainers", package: "swift-collections"),
            ]),
        .target(
            name: "XcodeLoader",
            dependencies: [
                "Xcode",
                "PathKit",

                .product(name: "BasicContainers", package: "swift-collections"),
                .product(name: "XcodeProj", package: "XcodeProj"),
                .product(name: "Subprocess", package: "swift-subprocess"),
            ]),
        .testTarget(
            name: "XcodeTests",
            dependencies: ["Xcode", "XcodeLoader", "BazelizeKit"]),
        .testTarget(
            name: "RepoEnumCoreTests",
            dependencies: ["RepoEnumCore"]),

        .target(
            name: "PluginLoader",
            dependencies: [
                "PathKit",
                "Util",
                "Xcode",
                .product(name: "Subprocess", package: "swift-subprocess"),
            ]),
    ])
