# Generated using Bazelize 0.0.4 - https://github.com/XCodeBazelize/Bazelize

load("@Plist//build-system/ios-utils:plist_fragment.bzl", "plist_fragment")
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_unit_test")
load("@rules_cc//cc:defs.bzl", "objc_library")

objc_library(
    name = "Framework3Tests_objc",
    module_name = "Framework3Tests",
    srcs = [
        "//Framework3Tests:Framework3Tests.m",
    ],
    # hdrs = None,
    enable_modules = True,
    # pch = None,
    copts = [
        "-fblocks",
        "-fobjc-arc",
        "-fPIC",
        "-fmodule-name=Framework3Tests",
    ],
    testonly = True,
    # defines = None,
    # linkopts = None,
    includes = [
        ".",
    ],
    deps = [
        "//Framework3:Framework3_library",
    ],
    visibility = [
        "//visibility:private",
    ],
)

alias(
    name = "Framework3Tests_library",
    actual = "Framework3Tests_objc",
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
    name = "Framework3Tests",
    minimum_os_version = "16.2",
    deps = [
        ":Framework3Tests_library",
    ],
    visibility = [
        "//visibility:public",
    ],
)