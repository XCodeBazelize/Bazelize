# Generated using Bazelize 0.0.4 - https://github.com/XCodeBazelize/Bazelize

load("@Plist//build-system/ios-utils:plist_fragment.bzl", "plist_fragment")
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_unit_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "ExampleTests_swift",
    module_name = "ExampleTests",
    srcs = [
        "//ExampleTests:ExampleTests.swift",
    ],
    testonly = True,
    deps = [
        "//Example:Example_library",
    ],
    # data = None,
    defines = None,
    visibility = [
        "//visibility:private",
    ],
)

alias(
    name = "ExampleTests_library",
    actual = "ExampleTests_swift",
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

ios_unit_test(
    name = "ExampleTests",
    minimum_os_version = "16.2",
    deps = [
        ":ExampleTests_library",
    ],
    visibility = [
        "//visibility:public",
    ],
)