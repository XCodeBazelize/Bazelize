load("@build_bazel_rules_apple//apple:macos.bzl", "macos_unit_test")
load("@build_bazel_rules_swift//swift:swift_binary.bzl", "swift_binary")
load("@build_bazel_rules_swift//swift:swift_library.bzl", "swift_library")

swift_binary(
    name = "GeneratePrebuild",
    copts = [
        "-I",
        "__BAZEL_SWIFT_TOOLCHAIN_PATH__/usr/lib/swift/pm/PluginAPI",
        "-package-description-version",
        "6.0.0",
    ],
    linkopts = [
        "-L",
        "__BAZEL_XCODE_DEVELOPER_DIR__/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/PluginAPI",
        "-lPackagePlugin",
        "-Xlinker",
        "-rpath",
        "-Xlinker",
        "__BAZEL_XCODE_DEVELOPER_DIR__/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/PluginAPI",
    ],
    module_name = "GeneratePrebuild",
    srcs = glob([
        "Sources/GeneratePrebuild/**/*.swift",
    ]),
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
swift_library(
    name = "PrebuildPlugin",
    alwayslink = True,
    always_include_developer_search_paths = True,
    copts = [
        "-DSWIFT_PACKAGE",
        "-Xcc",
        "-DSWIFT_PACKAGE",
    ],
    module_name = "PrebuildPlugin",
    package_name = "PrebuildPlugin",
    srcs = glob([
        "Generated/PrebuildPluginPlugin/**/*.swift",
        "Sources/PrebuildPlugin/**/*.swift",
    ], exclude = [
        "Sources/PrebuildPlugin/**/*.docc/**",
        "Sources/PrebuildPlugin/**/*.xcprivacy/**",
    ], allow_empty = True),
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
swift_library(
    name = "PrebuildPluginTests_library",
    alwayslink = True,
    always_include_developer_search_paths = True,
    copts = [
        "-DSWIFT_PACKAGE",
        "-Xcc",
        "-DSWIFT_PACKAGE",
    ],
    module_name = "PrebuildPluginTests",
    package_name = "PrebuildPlugin",
    srcs = glob([
        "Sources/PrebuildPluginTests/**/*.swift",
    ], exclude = [
        "Sources/PrebuildPluginTests/**/*.docc/**",
        "Sources/PrebuildPluginTests/**/*.xcprivacy/**",
    ], allow_empty = True),
    deps = [
        ":PrebuildPlugin",
    ],
    tags = [
        "manual",
    ],
    testonly = True,
    visibility = [
        "//visibility:private",
    ],
)
macos_unit_test(
    name = "PrebuildPluginTests",
    deps = [
        ":PrebuildPluginTests_library",
    ],
    minimum_os_version = "12.0",
    visibility = [
        "//visibility:public",
    ],
)