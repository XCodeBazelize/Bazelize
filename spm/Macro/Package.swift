// swift-tools-version: 6.0

import CompilerPluginSupport
import PackageDescription

/// A macro: a target the compiler loads as a plugin while it compiles another
/// target of the same package.
let package = Package(
    name: "Macro",
    /// The host the macro is built for. Without it SwiftPM builds it for the
    /// oldest macOS it supports and swift-syntax declares a newer one, which is
    /// a build failure rather than a macro.
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "Stringify", targets: ["Stringify"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "600.0.0"),
    ],
    targets: [
        .macro(
            name: "StringifyMacros",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ]),
        .target(
            name: "Stringify",
            dependencies: ["StringifyMacros"]),
        .testTarget(
            name: "StringifyTests",
            dependencies: ["Stringify"]),
    ])
