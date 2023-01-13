# Generated using Bazelize 0.0.3 - https://github.com/XCodeBazelize/Bazelize

load("@Plist//build-system/ios-utils:plist_fragment.bzl", "plist_fragment")
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_ui_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "ExampleUITests_swift",
    module_name = "ExampleUITests",
    srcs = [
        "//ExampleUITests:ExampleUITests.swift",
        "//ExampleUITests:ExampleUITestsLaunchTests.swift",
    ],
    testonly = True,
    # deps = None,
    # data = None,
    defines = None,
    visibility = [
        "//visibility:private",
    ],
)

alias(
    name = "ExampleUITests_library",
    actual = "ExampleUITests_swift",
    visibility = [
        "//visibility:public",
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

ios_ui_test(
    name = "ExampleUITests",
    test_host = "//Example:Example",
    minimum_os_version = "16.2",
    deps = [
        ":ExampleUITests_library",
    ],
    visibility = [
        "//visibility:public",
    ],
)