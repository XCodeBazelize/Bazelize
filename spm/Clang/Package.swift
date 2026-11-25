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
        /// More modules than targets, in every place clang looks for a map.
        ///
        /// `CPair` has no map of its own, so SwiftPM names a module after it with
        /// `include` as the umbrella. Beside it, `include/CPairInner` links to a
        /// directory whose map declares `CPairInner` — the shape of
        /// indexstore-db's `IndexStoreDB_CIndexStoreDB` up to swift-6.1 — and
        /// `include/CPairParts` is a real directory whose map infers a submodule
        /// per header and holds a link back to itself.
        .target(name: "CPair"),
        /// The map the target ships declares a second module after its own.
        .target(name: "CMany"),
        /// The map declares only a module of another name: there is no `CHidden`
        /// to import.
        .target(name: "CHidden", dependencies: ["CEmpty"]),
        /// The map declares nothing, so the headers are only included by path.
        .target(name: "CEmpty"),
        .target(
            name: "Consumer",
            dependencies: ["CObject", "CxxLib", "CPair", "CMany", "CHidden"],
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
        /// compile is sandboxed, so its `@import`s of the modules a map other
        /// than the target's own declares also say that map is an input rather
        /// than a file left lying around.
        .testTarget(
            name: "CObjectTests",
            dependencies: ["CObject", "CPair", "CMany", "CHidden"]),
    ],
    cLanguageStandard: .c11,
    cxxLanguageStandard: .gnucxx17)
