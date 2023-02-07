# Generated using Bazelize 0.0.4 - https://github.com/XCodeBazelize/Bazelize

load("@Plist//build-system/ios-utils:plist_fragment.bzl", "plist_fragment")
load("@rules_cc//cc:defs.bzl", "objc_library")

objc_library(
    name = "Static2_objc",
    module_name = "Static2",
    srcs = [
        "//Static2:Static2.m",
    ],
    hdrs = [
        "//Static2:Static2.h",
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
    name = "Static2_library",
    actual = "Static2_objc",
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
    <string>$(MARKETING_VERSION)</string>
    <key>CFBundleVersion</key>
    <string>$(CURRENT_PROJECT_VERSION)</string>
    ''',
    visibility = [
        "//visibility:private",
    ],
)

alias(
    name = "Static2",
    actual = "Static2_library",
    visibility = [
        "//visibility:public",
    ],
)