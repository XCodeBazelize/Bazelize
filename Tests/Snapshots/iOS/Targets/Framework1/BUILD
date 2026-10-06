# Generated using Bazelize 0.1.0 - https://github.com/XCodeBazelize/Bazelize

load("@Plist//build-system/ios-utils:plist_fragment.bzl", "plist_fragment")
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_framework")
load("@build_bazel_rules_swift//swift:swift_library.bzl", "swift_library")

swift_library(
    name = "Framework1_swift",
    alwayslink = True,
    copts = [
        "-swift-version",
        "5",
        "-enable-bare-slash-regex",
    ],
    module_name = "Framework1",
    srcs = [
        "Sources/Framework1/Test.swift",
    ],
    deps = [
        "//Targets/Framework2:Framework2_library",
        "//Targets/Static:Static_library",
    ],
    # data = None,
    defines = select({
        "//:Debug": [
            "DEBUG",
        ],
        "//:Release": None,
    }),
    linkopts = [
        "-L$$(DT_TOOLCHAIN_DIR)/usr/lib/swift/iphoneos",
    ],
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
    name = "Framework1_library",
    actual = "Framework1_swift",
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
    <string>FMWK</string>
    ''',
    visibility = [
        "//visibility:private",
    ],
)
plist_fragment(
    name = "plist_default",
    extension = "plist",
    template = '''
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    ''',
    visibility = [
        "//visibility:private",
    ],
)
ios_framework(
    name = "Framework1",
    bundle_id = "com.bazel.Example.Framework1",
    deps = [
        ":Framework1_library",
    ],
    families = [
        "iphone",
        "ipad",
    ],
    infoplists = [
        ":plist_file",
        ":plist_default",
    ],
    minimum_os_version = "16.2",
    # resources = None,
    # strings = None,
    visibility = [
        "//visibility:public",
    ],
)