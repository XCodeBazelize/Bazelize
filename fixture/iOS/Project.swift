import ProjectDescription

let deploymentTargets = DeploymentTargets.iOS("16.2")

func settings(_ values: SettingsDictionary = [:]) -> Settings {
    .settings(
        base: [
            "IPHONEOS_DEPLOYMENT_TARGET": "16.2",
            "SWIFT_VERSION": "5.0",
        ].merging(values) { _, value in value })
}

/// `Static2.h` refuses to compile unless `BAZELIZE_OTHER_FLAGS` is defined, and
/// only these two settings define it: `OTHER_CFLAGS` for a clang compile,
/// `-Xcc` in `OTHER_SWIFT_FLAGS` for the clang importer Swift builds that
/// module with. Every target that compiles the header — its own, and everyone
/// who imports the module, directly or through another target — carries them,
/// which is what Xcode requires of such a project too.
let otherFlags: SettingsDictionary = [
    "OTHER_CFLAGS": "-DBAZELIZE_OTHER_FLAGS",
    "OTHER_SWIFT_FLAGS": "-Xcc -DBAZELIZE_OTHER_FLAGS",
]

func target(
    _ name: String,
    product: Product,
    sources: SourceFilesList,
    dependencies: [TargetDependency] = [],
    headers: Headers? = nil,
    resources: ResourceFileElements? = nil,
    settings targetSettings: SettingsDictionary = [:]
) -> Target {
    .target(
        name: name,
        destinations: .iOS,
        product: product,
        bundleId: "com.bazel.\(name)",
        deploymentTargets: deploymentTargets,
        /// A framework Xcode embeds is validated when the app is built, and one
        /// with no `Info.plist` fails that validation.
        infoPlist: product == .app || product == .framework
            || product == .unitTests || product == .uiTests
            ? .extendingDefault(with: [:])
            : nil,
        sources: sources,
        resources: resources,
        headers: headers,
        dependencies: dependencies,
        settings: settings(targetSettings))
}

let project = Project(
    name: "Example",
    organizationName: "com.bazel",
    options: .options(
        automaticSchemesOptions: .enabled(),
        defaultKnownRegions: ["en", "Base", "zh-Hant"],
        developmentRegion: "en"),
    packages: [
        .remote(
            url: "https://github.com/Flight-School/AnyCodable",
            requirement: .upToNextMajor(from: "0.6.7")),
        .local(path: "Local1"),
    ],
    settings: settings(),
    targets: [
        .target(
            name: "MacBundle",
            destinations: .macOS,
            product: .bundle,
            bundleId: "com.bazel.MacBundle",
            deploymentTargets: .macOS("13.0"),
            infoPlist: .extendingDefault(with: [:]),
            sources: ["MacBundle/**/*.swift"],
            resources: [.folderReference(path: "MacBundle/Resources")],
            settings: settings()),
        target(
            "Static",
            product: .staticLibrary,
            sources: ["Static/**/*.swift"]),
        target(
            "Static2",
            product: .staticLibrary,
            sources: ["Static2/**/*.m"],
            headers: .headers(public: ["Static2/**/*.h"]),
            settings: otherFlags),
        target(
            "StaticFramework1",
            product: .staticFramework,
            sources: ["StaticFramework1/**/*.swift"]),
        target(
            "Framework3",
            product: .framework,
            sources: ["Framework3/**/*.m"],
            headers: .headers(public: ["Framework3/**/*.h"])),
        target(
            "Framework2",
            product: .framework,
            sources: ["Framework2/**/*.swift"],
            headers: .headers(public: ["Framework2/**/*.h"])),
        target(
            "Framework1",
            product: .framework,
            sources: ["Framework1/**/*.swift"],
            dependencies: [
                .target(name: "Framework2"),
                .target(name: "Static"),
            ],
            headers: .headers(public: ["Framework1/**/*.h"])),
        target(
            "Example",
            product: .app,
            sources: ["Example/**/*.swift"],
            dependencies: [
                .target(name: "Framework1"),
                .target(name: "Framework3"),
                .target(name: "Static2"),
                .target(name: "StaticFramework1"),
                .package(product: "AnyCodable"),
                .package(product: "LocalLib1"),
                .package(product: "LocalLib2"),
                .xcframework(path: "SVProgressHUD.xcframework"),
            ],
            resources: [
                "Example/Assets.xcassets",
                "Example/Preview Content/**",
                "Example/*.lproj/**",
            ],
            settings: otherFlags.merging([
                "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
                "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
                "DEVELOPMENT_ASSET_PATHS": "\"Example/Preview Content\"",
                /// `-D` reaches Swift as a condition, `-Xcc -D` the importer.
                "OTHER_SWIFT_FLAGS": "-DYDebug -D A -Xcc -DBAZELIZE_OTHER_FLAGS",
            ]) { _, value in value }),
        target(
            "ExampleTests",
            product: .unitTests,
            sources: ["ExampleTests/**/*.swift"],
            dependencies: [.target(name: "Example")],
            settings: otherFlags),
        target(
            "Framework1Tests",
            product: .unitTests,
            sources: ["Framework1Tests/**/*.swift"],
            dependencies: [
                .target(name: "Example"),
                .target(name: "Framework1"),
            ],
            settings: otherFlags),
        target(
            "Framework2Tests",
            product: .unitTests,
            sources: ["Framework2Tests/**/*.swift"],
            dependencies: [
                .target(name: "Example"),
                .target(name: "Framework2"),
            ],
            settings: otherFlags),
        target(
            "Framework3Tests",
            product: .unitTests,
            sources: ["Framework3Tests/**/*.m"],
            dependencies: [
                .target(name: "Example"),
                .target(name: "Framework3"),
            ],
            settings: otherFlags),
        target(
            "ExampleUITests",
            product: .uiTests,
            sources: ["ExampleUITests/**/*.swift"],
            dependencies: [.target(name: "Example")]),
    ])
