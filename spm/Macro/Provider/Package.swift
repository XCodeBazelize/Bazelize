// swift-tools-version: 6.0

import CompilerPluginSupport
import PackageDescription

/// The package next door, which ships a macro: the compiler has to load its
/// plugin while it compiles whoever uses the macro, and that is a package away
/// from where the plugin is built.
let package = Package(
    name: "Provider",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "Provider", targets: ["Provider"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "600.0.0"),
    ],
    targets: [
        .macro(
            name: "ProviderMacros",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ]),
        .target(
            name: "Provider",
            dependencies: ["ProviderMacros"]),
    ])
