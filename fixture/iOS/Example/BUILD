# Generated using Bazelize 0.0.3 - https://github.com/XCodeBazelize/Bazelize

load("@Plist//build-system/ios-utils:plist_fragment.bzl", "plist_fragment")
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

filegroup(
    name = "Assets",
    srcs = glob([
        "Assets.xcassets/**",
        "Preview Content/Preview Assets.xcassets/**",
    ]),
    visibility = [
        "//visibility:private",
    ],
)

swift_library(
    name = "Example_swift",
    module_name = "Example",
    srcs = [
        "//Example:ContentView.swift",
        "//Example:ExampleApp.swift",
        "//Example:Test.swift",
    ],
    testonly = False,
    deps = [
        "//Framework1:Framework1_library",
        "//Framework3:Framework3_library",
        "//Static2:Static2_library",
        "@swiftpkg_anycodable//:Sources_AnyCodable",
        "@swiftpkg_local1//:Sources_LocalTarget1",
        "@swiftpkg_local1//:Sources_LocalTarget2",
        "@swiftpkg_local1//:Sources_LocalTarget3",
    ],
    data = [
        ":Assets",
    ],
    defines = select({
        "//:Debug": [
            "YDebug",
            "A",
        ],
        "//:Release": [
            "YRelease",
            "B",
        ]
    }),
    visibility = [
        "//visibility:private",
    ],
)

alias(
    name = "Example_library",
    actual = "Example_swift",
    visibility = [
        "//visibility:public",
    ],
)

plist_fragment(
    name = "plist_auto",
    extension = "plist",
    template = '''
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <true/>
    </dict>
    <key>UIApplicationSupportsIndirectInputEvents</key>
    <true/>
    <key>UILaunchScreen</key>
    <dict>
        <key>UILaunchScreen</key>
        <dict/>
    </dict>
    ''',
    visibility = [
        "//visibility:private",
    ],
)

plist_fragment(
    name = "plist_default",
    extension = "plist",
    template = '''
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    ''',
    visibility = [
        "//visibility:private",
    ],
)

filegroup(
    name = "Strings",
    srcs = glob([
        "en.lproj/Localizable.strings",
        "zh-Hant.lproj/Localizable.strings",
    ]),
    visibility = [
        "//visibility:private",
    ],
)

ios_application(
    name = "Example",
    bundle_id = "com.bazel.Example",
    families = [
        "iphone",
        "ipad",
    ],
    minimum_os_version = "16.2",
    infoplists = [
        ":plist_auto",
        ":plist_default",
    ],
    deps = [
        ":Example_library",
        "//Framework1:Framework1",
        "//Framework3:Framework3",
        "//Static2:Static2",
    ],
    # sdk_frameworks = None,
    strings = [
        ":Strings",
    ],
    visibility = [
        "//visibility:public",
    ],
)