import ProjectDescription

let deploymentTargets = DeploymentTargets.iOS("16.2")

func settings(_ values: SettingsDictionary = [:]) -> Settings {
    .settings(
        base: [
            "IPHONEOS_DEPLOYMENT_TARGET": "16.2",
            "SWIFT_VERSION": "5.0",
        ].merging(values) { _, value in value })
}

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
        infoPlist: product == .app || product == .unitTests || product == .uiTests
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
        target(
            "Static",
            product: .staticLibrary,
            sources: ["Static/**/*.swift"]),
        target(
            "Static2",
            product: .staticLibrary,
            sources: ["Static2/**/*.m"],
            headers: .headers(public: ["Static2/**/*.h"])),
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
            settings: [
                "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
                "DEVELOPMENT_ASSET_PATHS": "\"Example/Preview Content\"",
                "OTHER_SWIFT_FLAGS": "-DYDebug -D A",
            ]),
        target(
            "ExampleTests",
            product: .unitTests,
            sources: ["ExampleTests/**/*.swift"],
            dependencies: [.target(name: "Example")]),
        target(
            "Framework1Tests",
            product: .unitTests,
            sources: ["Framework1Tests/**/*.swift"],
            dependencies: [
                .target(name: "Example"),
                .target(name: "Framework1"),
            ]),
        target(
            "Framework2Tests",
            product: .unitTests,
            sources: ["Framework2Tests/**/*.swift"],
            dependencies: [
                .target(name: "Example"),
                .target(name: "Framework2"),
            ]),
        target(
            "Framework3Tests",
            product: .unitTests,
            sources: ["Framework3Tests/**/*.m"],
            dependencies: [
                .target(name: "Example"),
                .target(name: "Framework3"),
            ]),
        target(
            "ExampleUITests",
            product: .uiTests,
            sources: ["ExampleUITests/**/*.swift"],
            dependencies: [.target(name: "Example")]),
    ])
