# Generated using Bazelize 0.1.0 - https://github.com/XCodeBazelize/Bazelize

load("@Plist//build-system/ios-utils:plist_fragment.bzl", "plist_fragment")
load("@build_bazel_rules_swift//swift:swift_library.bzl", "swift_library")

swift_library(
    name = "StaticFramework1_swift",
    testonly = False,
    srcs = [
        "Sources/StaticFramework1/Test.swift",
    ],
    copts = [
        "-swift-version",
        "5",
        "-enable-bare-slash-regex",
    ],
    # data = None,
    defines = select({
        "//:Debug": [
            "DEBUG",
        ],
        "//:Release": None,
    }),
    module_name = "StaticFramework1",
    # swiftc_inputs = None,
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:private",
    ],
    # deps = None,
    alwayslink = True,
)

alias(
    name = "StaticFramework1_library",
    actual = "StaticFramework1_swift",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)

plist_fragment(
    name = "plist_default",
    extension = "plist",
    template = """
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    """,
    visibility = [
        "//visibility:private",
    ],
)

alias(
    name = "StaticFramework1",
    actual = "StaticFramework1_library",
    visibility = [
        "//visibility:public",
    ],
)
