# Generated using Bazelize 0.0.3 - https://github.com/XCodeBazelize/Bazelize

load("@Plist//build-system/ios-utils:plist_fragment.bzl", "plist_fragment")
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_framework")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "Framework1_swift",
    module_name = "Framework1",
    srcs = [
        "//Framework1:Test.swift",
    ],
    testonly = False,
    deps = [
        "//Framework2:Framework2_library",
        "//Static:Static_library",
    ],
    # data = None,
    defines = None,
    visibility = [
        "//visibility:private",
    ],
)

alias(
    name = "Framework1_library",
    actual = "Framework1_swift",
    visibility = [
        "//visibility:public",
    ],
)

plist_fragment(
    name = "plist_auto",
    extension = "plist",
    template = '''
    <!--<key><key>NSHumanReadableCopyright</key></key>-->
    <!--<key></key>-->
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

ios_framework(
    name = "Framework1",
    bundle_id = "com.bazel.Framework1",
    families = [
        "iphone",
        "ipad",
    ],
    minimum_os_version = "16.2",
    infoplists = [
        ":plist_auto",
    ],
    deps = [
        ":Framework1_library",
        "//Framework2:Framework2",
        "//Static:Static",
    ],
    visibility = [
        "//visibility:public",
    ],
)