# Generated using Bazelize 0.1.0 - https://github.com/XCodeBazelize/Bazelize

load("@Plist//build-system/ios-utils:plist_fragment.bzl", "plist_fragment")
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")
load("@build_bazel_rules_swift//swift:swift_library.bzl", "swift_library")
load("//tools:asset_symbols.bzl", "asset_symbols")

asset_symbols(
    name = "AssetSymbols",
    bundle_id = "com.bazel.Example",
    catalogs = glob([
        "Sources/Example/Assets.xcassets/**",
        "Sources/Example/Preview Content/Preview Assets.xcassets/**",
    ]),
    minimum_os_version = "16.2",
    platform = "iphoneos",
    visibility = [
        "//visibility:private",
    ],
)

filegroup(
    name = "Assets",
    srcs = glob(
        [
            "Sources/Example/Assets.xcassets/**",
            "Sources/Example/Preview Content/Preview Assets.xcassets/**",
        ],
        exclude = [
            "Sources/Example/Assets.xcassets/*.appiconset/**",
            "Sources/Example/Preview Content/Preview Assets.xcassets/*.appiconset/**",
        ],
    ),
    visibility = [
        "//visibility:private",
    ],
)

swift_library(
    name = "Example_swift",
    testonly = False,
    srcs = [
        "Sources/Derived/Sources/TuistAssets+Example.swift",
        "Sources/Derived/Sources/TuistBundle+Example.swift",
        "Sources/Derived/Sources/TuistStrings+Example.swift",
        "Sources/Example/ContentView.swift",
        "Sources/Example/ExampleApp.swift",
        "Sources/Example/Test.swift",
        ":AssetSymbols",
    ],
    copts = [
        "-swift-version",
        "5",
        "-enable-bare-slash-regex",
    ],
    data = [
        ":Assets",
    ],
    defines = select({
        "//:Debug": [
            "DEBUG",
            "YDebug",
            "A",
        ],
        "//:Release": [
            "YDebug",
            "A",
        ],
    }),
    linkopts = [
        "-L$$(DT_TOOLCHAIN_DIR)/usr/lib/swift/iphoneos",
    ],
    module_name = "Example",
    # swiftc_inputs = None,
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:private",
    ],
    deps = [
        "//Packages/AnyCodable",
        "//Packages/Local1:LocalLib1",
        "//Packages/Local1:LocalLib2",
        "//Prebuilt:SVProgressHUD",
        "//Targets/Framework1:Framework1_library",
        "//Targets/Framework3:Framework3_library",
        "//Targets/Static2:Static2_library",
        "//Targets/StaticFramework1:StaticFramework1_library",
    ],
    alwayslink = True,
)

alias(
    name = "Example_library",
    actual = "Example_swift",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)

plist_fragment(
    name = "plist_file",
    extension = "plist",
    template = """
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UIApplicationSceneManifest</key>
    <dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <false/>
    <key>UISceneConfigurations</key>
    <dict/>
    </dict>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
    <string>armv7</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationPortraitUpsideDown</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    """,
    visibility = [
        "//visibility:private",
    ],
)

filegroup(
    name = "Strings",
    srcs = [
        "Sources/Example/en.lproj/Localizable.strings",
        "Sources/Example/zh-Hant.lproj/Localizable.strings",
    ],
    visibility = [
        "//visibility:private",
    ],
)

ios_application(
    name = "Example",
    app_icons = glob([
        "Sources/Example/Assets.xcassets/AppIcon.appiconset/**",
    ]),
    bundle_id = "com.bazel.Example",
    # extensions = None,
    families = [
        "iphone",
        "ipad",
    ],
    frameworks = [
        "//Targets/Framework1:Framework1",
        "//Targets/Framework2:Framework2",
        "//Targets/Framework3:Framework3",
    ],
    infoplists = [
        ":plist_file",
    ],
    minimum_os_version = "16.2",
    resources = [
        ":Assets",
    ],
    # sdk_frameworks = None,
    strings = [
        ":Strings",
    ],
    visibility = [
        "//visibility:public",
    ],
    deps = [
        ":Example_library",
        "//Prebuilt:SVProgressHUD",
        "//Targets/Framework1",
        "//Targets/Framework3",
        "//Targets/Static2",
        "//Targets/StaticFramework1",
    ],
)
