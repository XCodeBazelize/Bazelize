load("@build_bazel_rules_swift//swift:swift_interop_hint.bzl", "swift_interop_hint")
load("@build_bazel_rules_swift//swift:swift_library.bzl", "swift_library")
load("@build_bazel_rules_swift//swift:swift_library_group.bzl", "swift_library_group")
load("@rules_cc//cc:defs.bzl", "objc_library")

swift_library(
    name = "LocalTarget1",
    package_name = "Local1",
    srcs = glob(
        [
            "Sources/LocalTarget1/**/*.swift",
        ],
        allow_empty = True,
        exclude = [
            "Sources/LocalTarget1/**/*.docc/**",
            "Sources/LocalTarget1/**/*.xcprivacy/**",
        ],
    ),
    always_include_developer_search_paths = True,
    copts = [
        "-DSWIFT_PACKAGE",
        "-Xcc",
        "-DSWIFT_PACKAGE",
    ],
    module_name = "LocalTarget1",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
    deps = [
        "//Packages/RxSwift",
    ],
    alwayslink = True,
)

swift_library(
    name = "LocalTarget2",
    package_name = "Local1",
    srcs = glob(
        [
            "Sources/LocalTarget2/**/*.swift",
        ],
        allow_empty = True,
        exclude = [
            "Sources/LocalTarget2/**/*.docc/**",
            "Sources/LocalTarget2/**/*.xcprivacy/**",
        ],
    ),
    always_include_developer_search_paths = True,
    copts = [
        "-DSWIFT_PACKAGE",
        "-Xcc",
        "-DSWIFT_PACKAGE",
    ],
    module_name = "LocalTarget2",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
    deps = [
        "//Packages/RxSwift",
    ],
    alwayslink = True,
)

swift_interop_hint(
    name = "LocalTarget3_interop",
    module_map = "Generated/LocalTarget3Interface/module.modulemap",
    module_name = "LocalTarget3",
)

objc_library(
    name = "LocalTarget3",
    srcs = glob(
        [
            "Sources/LocalTarget3/**/*.h",
            "Sources/LocalTarget3/**/*.m",
        ],
        allow_empty = True,
        exclude = [
            "Sources/LocalTarget3/**/*.docc/**",
            "Sources/LocalTarget3/**/*.xcprivacy/**",
            "Sources/LocalTarget3/include/**",
        ],
    ),
    hdrs = glob([
        "Generated/LocalTarget3Interface/**/*.h",
    ]),
    aspect_hints = [
        ":LocalTarget3_interop",
    ],
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
    alwayslink = True,
)

swift_library_group(
    name = "LocalLib1",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
    deps = [
        ":LocalTarget1",
        ":LocalTarget3",
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
