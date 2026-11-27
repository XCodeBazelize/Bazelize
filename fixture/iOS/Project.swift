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
    settings targetSettings: SettingsDictionary = [:])
    -> Target
{
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
            name: "ProductProbeFramework",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.bazel.ProductProbe.ProductProbeFramework",
            deploymentTargets: deploymentTargets,
            infoPlist: .extendingDefault(with: [:]),
            sources: ["ProductProbeFramework/**/*.m"],
            headers: .headers(public: ["ProductProbeFramework/**/*.h"]),
            settings: settings()),
        .target(
            name: "ProductProbeExtension",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "com.bazel.ProductProbe.Extension",
            deploymentTargets: deploymentTargets,
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "Product Probe Extension",
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.usernotifications.service",
                    "NSExtensionPrincipalClass": "$(PRODUCT_MODULE_NAME).NotificationService",
                ],
            ]),
            sources: ["ProductProbeExtension/**/*.swift"],
            settings: settings(["APPLICATION_EXTENSION_API_ONLY": "YES"])),
        target(
            "ProductProbe",
            product: .app,
            sources: ["ProductProbe/**/*.swift"],
            dependencies: [.target(name: "ProductProbeFramework"), .target(name: "ProductProbeExtension")],
            resources: ["ProductProbe/Probe.txt", "Example/Assets.xcassets", "ProductProbe/Assets.xcassets"],
            settings: [
                "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                "ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES": "AlternateIcon",
                "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
                "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
            ]),
        .target(
            name: "PerFileFlags",
            destinations: .macOS,
            product: .commandLineTool,
            bundleId: "com.bazel.PerFileFlags",
            deploymentTargets: .macOS("13.0"),
            infoPlist: nil,
            sources: [
                .glob("PerFileFlags/main.m"),
                .glob("PerFileFlags/Legacy.m", compilerFlags: "-fno-objc-arc"),
                .glob("PerFileFlags/Flagged.m", compilerFlags: "-DFILE_VALUE=73"),
            ],
            dependencies: [.sdk(name: "Foundation", type: .framework)],
            settings: settings(["CLANG_ENABLE_OBJC_ARC": "YES", "CLANG_ENABLE_MODULES": "YES"])),
        /// Xcode reads a list setting as shell words, so a quoted value with a
        /// space in it is one argument. `main.m` does not compile, link, or
        /// exit zero unless every value below reached clang or the linker so.
        .target(
            name: "QuotedFlags",
            destinations: .macOS,
            product: .commandLineTool,
            bundleId: "com.bazel.QuotedFlags",
            deploymentTargets: .macOS("13.0"),
            infoPlist: nil,
            sources: ["QuotedFlags/main.m"],
            dependencies: [.sdk(name: "Foundation", type: .framework)],
            settings: settings([
                "HEADER_SEARCH_PATHS": #"$(inherited) "$(SRCROOT)/QuotedFlags/Header Dir""#,
                "GCC_PREPROCESSOR_DEFINITIONS": #"$(inherited) QUOTED_MESSAGE='"two words"'"#,
                "OTHER_CFLAGS": #"$(inherited) "-DOTHER_MESSAGE=\"other words\"""#,
                "OTHER_LDFLAGS": #"$(inherited) -Xlinker "-alias" -Xlinker "_quoted_flags_symbol" -Xlinker "_quoted_flags_alias""#,
            ])),
        /// The iOS product types an app embeds besides a plain extension: an App
        /// Clip, an iMessage extension, and a sticker pack.
        target(
            "ProductKinds",
            product: .app,
            sources: ["ProductKinds/Application/**/*.swift"],
            dependencies: [
                .target(name: "ProductKindsClip"),
                .target(name: "ProductKindsMessages"),
                .target(name: "ProductKindsStickers"),
            ]),
        .target(
            name: "ProductKindsClip",
            destinations: .iOS,
            product: .appClip,
            bundleId: "com.bazel.ProductKinds.Clip",
            deploymentTargets: deploymentTargets,
            infoPlist: .extendingDefault(with: [:]),
            sources: ["ProductKinds/Clip/**/*.swift"],
            /// Tuist refuses an App Clip without it. The prefix is the signing
            /// team's, which nothing here signs with.
            entitlements: .dictionary([
                "com.apple.developer.parent-application-identifiers": ["$(AppIdentifierPrefix)com.bazel.ProductKinds"],
            ]),
            settings: settings()),
        .target(
            name: "ProductKindsMessages",
            destinations: .iOS,
            product: .messagesExtension,
            bundleId: "com.bazel.ProductKinds.Messages",
            deploymentTargets: deploymentTargets,
            infoPlist: .extendingDefault(with: [
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.message-payload-provider",
                    "NSExtensionPrincipalClass": "$(PRODUCT_MODULE_NAME).MessagesViewController",
                ],
            ]),
            sources: ["ProductKinds/Messages/**/*.swift"],
            settings: settings(["APPLICATION_EXTENSION_API_ONLY": "YES"])),
        .target(
            name: "ProductKindsStickers",
            destinations: .iOS,
            product: .stickerPackExtension,
            bundleId: "com.bazel.ProductKinds.Stickers",
            deploymentTargets: deploymentTargets,
            infoPlist: .extendingDefault(with: [:]),
            resources: ["ProductKinds/Stickers/Stickers.xcassets"],
            settings: settings()),
        /// A tvOS app and the Top Shelf extension it embeds.
        .target(
            name: "TVProductKinds",
            destinations: .tvOS,
            product: .app,
            bundleId: "com.bazel.TVProductKinds",
            deploymentTargets: .tvOS("17.0"),
            infoPlist: .extendingDefault(with: [:]),
            sources: ["TVProductKinds/Application/**/*.swift"],
            dependencies: [.target(name: "TVProductKindsTopShelf")],
            settings: settings()),
        .target(
            name: "TVProductKindsTopShelf",
            destinations: .tvOS,
            product: .tvTopShelfExtension,
            bundleId: "com.bazel.TVProductKinds.TopShelf",
            deploymentTargets: .tvOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.tv-top-shelf",
                    "NSExtensionPrincipalClass": "$(PRODUCT_MODULE_NAME).ContentProvider",
                ],
            ]),
            sources: ["TVProductKinds/TopShelf/**/*.swift"],
            settings: settings(["APPLICATION_EXTENSION_API_ONLY": "YES"])),
        /// A single-target watch app the iPhone app carries in `Watch/`, and the
        /// Intents extension the watch app carries.
        target(
            "WatchCompanion",
            product: .app,
            sources: ["WatchKinds/Companion/**/*.swift"],
            dependencies: [.target(name: "WatchCompanionWatch")]),
        .target(
            name: "WatchCompanionWatch",
            destinations: [.appleWatch],
            product: .app,
            bundleId: "com.bazel.WatchCompanion.watchkitapp",
            deploymentTargets: .watchOS("9.0"),
            infoPlist: .extendingDefault(with: [
                "WKApplication": true,
                "WKCompanionAppBundleIdentifier": "com.bazel.WatchCompanion",
            ]),
            sources: ["WatchKinds/Watch/**/*.swift"],
            dependencies: [.target(name: "WatchCompanionIntents")],
            settings: settings()),
        .target(
            name: "WatchCompanionIntents",
            destinations: [.appleWatch],
            product: .appExtension,
            bundleId: "com.bazel.WatchCompanion.watchkitapp.Intents",
            deploymentTargets: .watchOS("9.0"),
            infoPlist: .extendingDefault(with: [
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.intents-service",
                    "NSExtensionPrincipalClass": "$(PRODUCT_MODULE_NAME).IntentHandler",
                    "NSExtensionAttributes": ["IntentsSupported": ["INSendMessageIntent"]],
                ],
            ]),
            sources: ["WatchKinds/Intents/**/*.swift"],
            settings: settings(["APPLICATION_EXTENSION_API_ONLY": "YES"])),
        /// The watchOS 2 structure: a watch app with no code of its own around
        /// the WatchKit extension that has it.
        target(
            "Watch2Companion",
            product: .app,
            sources: ["WatchKinds/Companion2/**/*.swift"],
            dependencies: [.target(name: "Watch2CompanionWatch")]),
        .target(
            name: "Watch2CompanionWatch",
            destinations: [.appleWatch],
            product: .watch2App,
            bundleId: "com.bazel.Watch2Companion.watchkitapp",
            deploymentTargets: .watchOS("9.0"),
            infoPlist: .extendingDefault(with: [
                "WKCompanionAppBundleIdentifier": "com.bazel.Watch2Companion",
            ]),
            dependencies: [.target(name: "Watch2CompanionExtension")],
            settings: settings()),
        .target(
            name: "Watch2CompanionExtension",
            destinations: [.appleWatch],
            product: .watch2Extension,
            bundleId: "com.bazel.Watch2Companion.watchkitapp.watchkitextension",
            deploymentTargets: .watchOS("9.0"),
            infoPlist: .extendingDefault(with: [
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.watchkit",
                    "NSExtensionAttributes": ["WKAppBundleIdentifier": "com.bazel.Watch2Companion.watchkitapp"],
                ],
                "WKExtensionDelegateClassName": "$(PRODUCT_MODULE_NAME).ExtensionDelegate",
            ]),
            sources: ["WatchKinds/Extension/**/*.swift"],
            settings: settings(["APPLICATION_EXTENSION_API_ONLY": "YES"])),
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
        /// Swift and Objective-C in one target, with a binary framework's type
        /// in the Swift half's Objective-C interface: the Objective-C half
        /// imports `Mixed-Swift.h`, and that header imports the framework's
        /// module.
        target(
            "Mixed",
            product: .framework,
            sources: ["Mixed/**/*.swift", "Mixed/**/*.m"],
            dependencies: [
                .xcframework(path: "SVProgressHUD.xcframework"),
            ],
            headers: .headers(public: ["Mixed/**/*.h"])),
        target(
            "Example",
            product: .app,
            sources: ["Example/**/*.swift"],
            dependencies: [
                .target(name: "Framework1"),
                .target(name: "Framework3"),
                .target(name: "Mixed"),
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
        /// Swift tests. Besides the app, they `import Mixed`, which has to reach
        /// both the Objective-C and the Swift half of that framework.
        target(
            "ExampleTests",
            product: .unitTests,
            sources: ["ExampleTests/**/*.swift"],
            dependencies: [
                .target(name: "Example"),
                .target(name: "Mixed"),
            ],
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
        /// Objective-C tests. Besides Framework3, they `@import Mixed`, which has
        /// to reach both the Objective-C and the Swift half of that framework.
        target(
            "Framework3Tests",
            product: .unitTests,
            sources: ["Framework3Tests/**/*.m"],
            dependencies: [
                .target(name: "Example"),
                .target(name: "Framework3"),
                .target(name: "Mixed"),
            ],
            settings: otherFlags),
        target(
            "ExampleUITests",
            product: .uiTests,
            sources: ["ExampleUITests/**/*.swift"],
            dependencies: [.target(name: "Example")]),
    ])
