# Generated using Bazelize 0.0.5 - https://github.com/XCodeBazelize/Bazelize

load("@Plist//build-system/ios-utils:plist_fragment.bzl", "plist_fragment")
load("@build_bazel_rules_apple//apple:macos.bzl", "macos_bundle")
load("@build_bazel_rules_swift//swift:swift_library.bzl", "swift_library")

filegroup(
    name = "Resources",
    srcs = glob([
        "Sources/MacBundle/Resources/**",
    ]),
    visibility = [
        "//visibility:private",
    ],
)
swift_library(
    name = "MacBundle_swift",
    alwayslink = True,
    module_name = "MacBundle",
    srcs = [
        "Sources/Derived/Sources/TuistBundle+MacBundle.swift",
        "Sources/MacBundle/MacBundle.swift",
    ],
    # deps = None,
    # data = None,
    defines = select({
        "//:Debug": [
            "DEBUG",
        ],
        "//:Release": None,
    }),
    # swiftc_inputs = None,
    tags = [
        "manual",
    ],
    testonly = False,
    visibility = [
        "//visibility:private",
    ],
)
alias(
    name = "MacBundle_library",
    actual = "MacBundle_swift",
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
    template = '''
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
    <string>BNDL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright ©. All rights reserved.</string>
    ''',
    visibility = [
        "//visibility:private",
    ],
)
macos_bundle(
    name = "MacBundle",
    bundle_id = "com.bazel.MacBundle",
    deps = [
        ":MacBundle_library",
    ],
    infoplists = [
        ":plist_file",
    ],
    minimum_os_version = "13.0",
    resources = [
        ":Resources",
    ],
    # strings = None,
    visibility = [
        "//visibility:public",
    ],
)