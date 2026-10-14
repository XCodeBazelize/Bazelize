# Generated using Bazelize 0.1.0 - https://github.com/XCodeBazelize/Bazelize

load("@Plist//build-system/ios-utils:plist_fragment.bzl", "plist_fragment")
load("@rules_cc//cc:defs.bzl", "objc_library")

objc_library(
    name = "Static2_objc",
    srcs = [
        "Sources/Static2/Static2.m",
    ],
    hdrs = [
        "Headers/Static2/Static2.h",
    ],
    # deps = None,
    # data = None,
    copts = [
        "-fblocks",
        "-fobjc-arc",
        "-fPIC",
        "-fmodule-name=Static2",
        "-DDEBUG=1",
    ],
    enable_modules = True,
    includes = [
        ".",
        "..",
        "Headers",
        "Headers/Static2",
        "Sources/Static2",
    ],
    linkopts = [
        "-ObjC",
    ],
    module_name = "Static2",
    # sdk_dylibs = None,
    sdk_frameworks = [
        "Foundation",
    ],
    tags = [
        "manual",
    ],
    testonly = False,
    visibility = [
        "//visibility:private",
    ],
    # weak_sdk_frameworks = None,
)
alias(
    name = "Static2_library",
    actual = "Static2_objc",
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
    template = '''
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