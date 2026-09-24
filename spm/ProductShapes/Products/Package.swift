// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Products",
    products: [
        .library(name: "Combined", targets: ["First", "Second"]),
        /// The product keeps this name; the target rule must move aside.
        .library(name: "First", targets: ["First", "Second"]),
        .library(name: "StaticCombined", type: .static, targets: ["First", "Second"]),
        .library(name: "DynamicCombined", type: .dynamic, targets: ["First", "Second"]),
        .executable(name: "renamed-tool", targets: ["Tool"]),
    ],
    targets: [
        .target(name: "First"),
        /// `package` access reaches across the targets of one package, so this
        /// one links the other.
        .target(name: "Second", dependencies: ["First"]),
        .executableTarget(name: "Tool"),
    ])
