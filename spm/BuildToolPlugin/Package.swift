// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BuildToolPlugin",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        /// Named after the target it holds: a plugin's tool is looked up as a
        /// product by Swift 6.3, which cannot load this package at all when the
        /// two names differ.
        .executable(name: "TbCodeGenerater", targets: ["TbCodeGenerater"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "TbCodeGenerater",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "TbParser",
            ],
            exclude: [
                "tds",
            ],
            resources: [
                .copy("tds"),
            ]
        ),
        .target(name: "TbParser"),
        
        .plugin(
            name: "GenerateTbTestCode",
            capability: .buildTool(),
            dependencies: [
                "TbCodeGenerater",
            ]
        ),
        .testTarget(
            name: "TbParserTests",
            dependencies: [
                "TbParser"
            ],
            plugins: [
                "GenerateTbTestCode",
            ]
        )
    ]
)
