# Generated using Bazelize 0.0.3 - https://github.com/XCodeBazelize/Bazelize

load("@Plist//build-system/ios-utils:plist_fragment.bzl", "plist_fragment")
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_framework")
load("@rules_cc//cc:defs.bzl", "objc_library")

objc_library(
    name = "Framework3_objc",
    module_name = "Framework3",
    srcs = [
        "//Framework3:Framework.m",
    ],
    hdrs = [
        "//Framework3:Framework3.h",
        "//Framework3:Framework.h",
    ],
    # pch = None,
    # copts = None,
    # defines = None,
    # linkopts = None,
    # includes = None,
    # deps = None,
    visibility = [
        "//visibility:private",
    ],
)

alias(
    name = "Framework3_library",
    actual = "Framework3_objc",
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
    name = "Framework3",
    bundle_id = "com.yume190.Framework3",
    families = [
        "iphone",
        "ipad",
    ],
    minimum_os_version = "16.2",
    infoplists = [
        ":plist_auto",
    ],
    deps = [
        ":Framework3_library",
    ],
    visibility = [
        "//visibility:public",
    ],
)