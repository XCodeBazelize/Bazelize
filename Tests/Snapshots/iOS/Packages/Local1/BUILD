load("@build_bazel_rules_swift//swift:swift_interop_hint.bzl", "swift_interop_hint")
load("@build_bazel_rules_swift//swift:swift_library.bzl", "swift_library")
load("@build_bazel_rules_swift//swift:swift_library_group.bzl", "swift_library_group")
load("@rules_cc//cc:defs.bzl", "objc_library")

swift_library(
    name = "LocalTarget1",
    alwayslink = True,
    always_include_developer_search_paths = True,
    copts = [
        "-DSWIFT_PACKAGE",
        "-Xcc",
        "-DSWIFT_PACKAGE",
    ],
    module_name = "LocalTarget1",
    package_name = "Local1",
    srcs = glob([
        "Sources/LocalTarget1/**/*.swift",
    ], exclude = [
        "Sources/LocalTarget1/**/*.docc/**",
        "Sources/LocalTarget1/**/*.xcprivacy/**",
    ], allow_empty = True),
    deps = [
        "//Packages/RxSwift:RxSwift",
    ],
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
swift_library(
    name = "LocalTarget2",
    alwayslink = True,
    always_include_developer_search_paths = True,
    copts = [
        "-DSWIFT_PACKAGE",
        "-Xcc",
        "-DSWIFT_PACKAGE",
    ],
    module_name = "LocalTarget2",
    package_name = "Local1",
    srcs = glob([
        "Sources/LocalTarget2/**/*.swift",
    ], exclude = [
        "Sources/LocalTarget2/**/*.docc/**",
        "Sources/LocalTarget2/**/*.xcprivacy/**",
    ], allow_empty = True),
    deps = [
        "//Packages/RxSwift:RxSwift",
    ],
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
swift_interop_hint(
    name = "LocalTarget3_interop",
    module_map = "Generated/LocalTarget3Interface/module.modulemap",
    module_name = "LocalTarget3",
)
objc_library(
    name = "LocalTarget3",
    aspect_hints = [
        ":LocalTarget3_interop",
    ],
    srcs = glob([
        "Sources/LocalTarget3/**/*.h",
        "Sources/LocalTarget3/**/*.m",
    ], exclude = [
        "Sources/LocalTarget3/**/*.docc/**",
        "Sources/LocalTarget3/**/*.xcprivacy/**",
        "Sources/LocalTarget3/include/**",
    ], allow_empty = True),
    hdrs = glob([
        "Generated/LocalTarget3Interface/**/*.h",
    ]),
    alwayslink = True,
    copts = [
        "-fmodule-name=LocalTarget3",
        "-DSWIFT_PACKAGE",
    ],
    enable_modules = True,
    includes = [
        "Generated/LocalTarget3Interface",
    ],
    module_name = "LocalTarget3",
    tags = [
        "manual",
    ],
    textual_hdrs = [
        "Generated/LocalTarget3Interface/module.modulemap",
    ],
    visibility = [
        "//visibility:public",
    ],
)
swift_library_group(
    name = "LocalLib1",
    deps = [
        ":LocalTarget1",
        ":LocalTarget3",
    ],
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
alias(
    name = "LocalLib2",
    actual = ":LocalTarget2",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)