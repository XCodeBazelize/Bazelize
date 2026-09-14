// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Bazelize",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "bazelize", targets: ["Bazelize"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.

        .package(url: "https://github.com/tuist/XcodeProj", from: "9.16.0"),
        .package(url: "https://github.com/Flight-School/AnyCodable", from: "0.6.7"),
        .package(url: "https://github.com/jpsim/Yams", from: "6.2.2"),
        .package(url: "https://github.com/kylef/PathKit", from: "1.0.1"),

        .package(url: "https://github.com/swiftlang/swift-subprocess", from: "1.0.0"),

        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.8.2"),

        /// SwiftPMDataModel for the legacy `XCode` target.
        /// 6.3+ requires macOS 14, which would raise this package's platform floor.
        .package(
            url: "https://github.com/apple/swift-package-manager",
            branch: "swift-6.2.4-RELEASE"),
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
                "XCode2",
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
                "XCode2",
                "Util",
                "Starlark",
                "PluginLoader",

                .product(name: "XcodeProj", package: "XcodeProj"),
            ]),
        .target(
            name: "RepoEnumCore",
            dependencies: [
                "Yams",
            ]),
        .plugin(
            name: "RepoEnumPlugin",
            capability: .command(
                intent: .custom(
                    verb: "repo-enum",
                    description: "Generate Repo+*.swift files from GitHub tags."),
                permissions: [
                    .allowNetworkConnections(
                        scope: .all(),
                        reason: "Fetch GitHub tags for configured repositories."),
                    .writeToPackageDirectory(
                        reason: "Write generated Repo enum files into the package directory."),
                ]),
            dependencies: [
                "RepoEnumGenerator",
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
            name: "XCode",
            dependencies: [
                "Util",
                "Starlark",
                "AnyCodable",

                .product(name: "XcodeProj", package: "XcodeProj"),
                .product(name: "SwiftPMDataModel-auto", package: "swift-package-manager"),
            ]),
        .target(
            name: "XCode2",
            dependencies: [
                "PathKit",
                "AnyCodable",

                .product(name: "XcodeProj", package: "XcodeProj"),
            ],
            path: "Sources/XCode2"),
        .testTarget(
            name: "XCode2Tests",
            dependencies: ["XCode2", "BazelizeKit"]),
        .testTarget(
            name: "RepoEnumCoreTests",
            dependencies: ["RepoEnumCore"]),
        .testTarget(
            name: "XCodeTests",
            dependencies: ["XCode"]),

        .target(
            name: "PluginLoader",
            dependencies: [
                "PathKit",
                "Util",
                "XCode",
                .product(name: "Subprocess", package: "swift-subprocess"),
            ]),
    ])
