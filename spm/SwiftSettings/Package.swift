// swift-tools-version: 6.2

import PackageDescription

/// What a target compiles and links with beyond the defaults: every kind of
/// `SwiftSetting` and `LinkerSetting`, each one observable — a setting that did
/// not reach the compiler fails the build, and one that did not reach the
/// linker leaves a symbol undefined.
let package = Package(
    name: "SwiftSettings",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "SwiftSettings", targets: ["SwiftSettings"]),
    ],
    targets: [
        .target(
            name: "SwiftSettings",
            swiftSettings: [
                .define("MANIFEST_DEFINE"),
                /// Not the language mode: that one the package declares, and
                /// this target inherits.
                .enableUpcomingFeature("MemberImportVisibility"),
                .enableExperimentalFeature("Extern"),
                .strictMemorySafety(),
                .defaultIsolation(MainActor.self),
                .unsafeFlags(["-DUNSAFE_DEFINE"]),
            ],
            linkerSettings: [
                /// `crc32` is in libz and nowhere else, so the call only links
                /// when the library does.
                .linkedLibrary("z"),
                /// Nothing here imports Security, so the framework is linked
                /// because the manifest says so or not at all.
                .linkedFramework("Security"),
                /// An alias the program calls: without the flags there is no
                /// such symbol.
                .unsafeFlags([
                    "-Xlinker", "-alias",
                    "-Xlinker", "_swiftsettings_probe",
                    "-Xlinker", "_swiftsettings_probe_alias",
                ]),
            ]),
        /// The package's mode is the default, not the rule: a target that names
        /// one of its own is compiled in that.
        .target(
            name: "LanguageModeOverride",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]),
        .testTarget(
            name: "SwiftSettingsTests",
            dependencies: ["LanguageModeOverride", "SwiftSettings"]),
    ],
    swiftLanguageModes: [.v5])
