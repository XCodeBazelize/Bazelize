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

        .package(url: "https://github.com/tuist/XcodeProj", from: "9.10.1"),
        .package(url: "https://github.com/Flight-School/AnyCodable", from: "0.6.7"),
        .package(url: "https://github.com/jpsim/Yams", from: "6.2.1"),
        .package(url: "https://github.com/kylef/PathKit", from: "1.0.1"),

        .package(url: "https://github.com/yume190/SwiftCommand", from: "1.1.3"),

        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.7.0"),

        /// tag: swift-DEVELOPMENT-SNAPSHOT-2023-01-28-a
        /// support async command
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
            ]),

        .target(
            name: "BazelRules",
            dependencies: [
                "RuleBuilder",
            ]),
        .testTarget(
            name: "BazelRulesTests",
            dependencies: ["BazelRules"]),
        .target(
            name: "RuleBuilder",
            dependencies: [
                "Util",
            ]),
        .testTarget(
            name: "RuleBuilderTests",
            dependencies: ["RuleBuilder"]),

        .target(
            name: "BazelizeKit",
            dependencies: [
                "Yams",

                "BazelRules",
                "XCode",
                "Util",
                "RuleBuilder",
                "PluginLoader",

                .product(name: "XcodeProj", package: "XcodeProj"),
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
                "RuleBuilder",
                "AnyCodable",

                .product(name: "XcodeProj", package: "XcodeProj"),
                .product(name: "SwiftPMDataModel-auto", package: "swift-package-manager"),
            ]),
        .testTarget(
            name: "XCodeTests",
            dependencies: ["XCode"]),

        .target(
            name: "PluginLoader",
            dependencies: [
                "PathKit",
                "Util",
                "XCode",
                "SwiftCommand",
            ]),
    ])
