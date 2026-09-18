// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "Local1",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "LocalLib1",
            targets: ["LocalTarget1", "LocalTarget3"]),
        .library(
            name: "LocalLib2",
            targets: ["LocalTarget2"]),
        .executable(
            name: "local1-tool",
            targets: ["Local1Tool"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/ReactiveX/RxSwift", from: "6.5.0"),
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "600.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .macro(
            name: "Local1Macros",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ]),
        .target(
            name: "LocalTarget1",
            dependencies: ["RxSwift", "Local1Macros"],
            plugins: ["Local1Gen"]),
        .target(
            name: "LocalTarget2",
            dependencies: ["RxSwift"]),
        .target(
            name: "LocalTarget3",
            plugins: ["Local1Gen"]),
        .executableTarget(
            name: "Local1Tool"),
        .plugin(
            name: "Local1Gen",
            capability: .buildTool(),
            dependencies: ["Local1Tool"]),
        .testTarget(
            name: "Local1Tests",
            dependencies: ["LocalTarget1"]),
    ])
