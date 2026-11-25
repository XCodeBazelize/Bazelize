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
                .unsafeFlags(["-DC_UNSAFE_FLAG"]),
            ]),
        .target(
            name: "CxxLib",
            cxxSettings: [
                .unsafeFlags(["-DCXX_UNSAFE_FLAG"]),
            ]),
        /// One target, two modules: SwiftPM names `CPair` after the target, and
        /// the module map in a subdirectory of `include` declares `CPairInner`,
        /// which clang finds through the header search path alone. The shape of
        /// indexstore-db's `IndexStoreDB_CIndexStoreDB` up to swift-6.1.
        .target(name: "CPair"),
        .target(
            name: "Consumer",
            dependencies: ["CObject", "CxxLib", "CPair"],
            swiftSettings: [
                .interoperabilityMode(.Cxx),
            ]),
        .testTarget(
            name: "ClangTests",
            dependencies: ["Consumer"],
            swiftSettings: [
                .interoperabilityMode(.Cxx),
            ]),
        /// A test target written in Objective-C: SwiftPM compiles it the way it
        /// compiles any C-family target, and so must the generated rules. Its
        /// compile is sandboxed, so its `@import CPairInner` also says the
        /// nested module map is an input rather than a file left lying around.
        .testTarget(
            name: "CObjectTests",
            dependencies: ["CObject", "CPair"]),
    ],
    cLanguageStandard: .c11,
    cxxLanguageStandard: .gnucxx17)
