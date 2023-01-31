// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Bazelize",
    platforms: [
        .macOS(.v11),
    ],
    products: [
        .executable(name: "bazelize", targets: ["Bazelize"]),
        .library(name: "Cocoapod", type: .dynamic, targets: ["Cocoapod"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.

        .package(url: "https://github.com/tuist/XcodeProj", from: "8.8.0"),
        .package(url: "https://github.com/Flight-School/AnyCodable", from: "0.6.6"),
        .package(url: "https://github.com/jpsim/Yams", from: "5.0.1"),
        .package(url: "https://github.com/kylef/PathKit", from: "1.0.1"),

        .package(url: "https://github.com/yume190/SwiftCommand", from: "1.1.3"),

        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.1.4"),

        .package(
            url: "https://github.com/apple/swift-package-manager",
            branch: "main"),
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
                "PluginInterface",

                "AnyCodable",

                .product(name: "XcodeProj", package: "XcodeProj"),
                .product(name: "SwiftPMDataModel-auto", package: "swift-package-manager"),
            ]),
        .testTarget(
            name: "XCodeTests",
            dependencies: ["XCode"]),

        .target(
            name: "Cocoapod",
            dependencies: [
                "PluginInterface",
                "Util",
                "AnyCodable",
                "PathKit",
            ]),
        .testTarget(
            name: "CocoapodTests",
            dependencies: ["Cocoapod"],
            resources: [
                .copy("Resource"),
            ]),

        .target(
            name: "PluginInterface",
            dependencies: ["PathKit"]),

        .target(
            name: "PluginLoader",
            dependencies: [
                "PathKit",
                "PluginInterface",
                "Util",
                "SwiftCommand",
            ]),

//        .testTarget(
//            name: "SwiftBazelGenTests",
//            dependencies: ["SwiftBazelGen"]),
    ])
