// swift-tools-version: 6.0

import PackageDescription

/// The C-family side: where a target's public headers are, what it searches
/// for its own, the defines it compiles with, C++ interoperability, and the
/// resource bundle a C target reaches without importing anything.
let package = Package(
    name: "Clang",
    products: [
        .library(name: "Consumer", targets: ["Consumer"]),
    ],
    targets: [
        .target(
            name: "CObject",
            /// A C-family target with resources gets the same bundle a Swift
            /// one does, reached through a header SwiftPM force-includes.
            resources: [
                .process("Resources"),
            ],
            /// Not `include`: the headers are where the manifest says they are.
            publicHeadersPath: "headers",
            cSettings: [
                .headerSearchPath("internal"),
                .define("C_FLAG"),
                .define("C_VALUE", to: "7"),
            ]),
        .target(name: "CxxLib"),
        .target(
            name: "Consumer",
            dependencies: ["CObject", "CxxLib"],
            swiftSettings: [
                .interoperabilityMode(.Cxx),
            ]),
        .testTarget(
            name: "ClangTests",
            dependencies: ["Consumer"],
            swiftSettings: [
                .interoperabilityMode(.Cxx),
            ]),
    ],
    cLanguageStandard: .c11,
    cxxLanguageStandard: .gnucxx17)
