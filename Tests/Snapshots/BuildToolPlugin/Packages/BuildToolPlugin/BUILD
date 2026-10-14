load("@build_bazel_rules_apple//apple:macos.bzl", "macos_unit_test")
load("@build_bazel_rules_swift//swift:swift_binary.bzl", "swift_binary")
load("@build_bazel_rules_swift//swift:swift_library.bzl", "swift_library")

swift_binary(
    name = "GenerateTbTestCode",
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
    module_name = "GenerateTbTestCode",
    srcs = glob([
        "Sources/GenerateTbTestCode/**/*.swift",
    ]),
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
swift_binary(
    name = "TbCodeGenerater",
    copts = [
        "-DSWIFT_PACKAGE",
        "-Xcc",
        "-DSWIFT_PACKAGE",
    ],
    deps = [
        "//Packages/swift-argument-parser:ArgumentParser",
        ":TbParser",
    ],
    module_name = "TbCodeGenerater",
    srcs = glob([
        "Sources/TbCodeGenerater/**/*.swift",
    ], exclude = [
        "Sources/TbCodeGenerater/**/*.docc/**",
        "Sources/TbCodeGenerater/**/*.xcprivacy/**",
        "Sources/TbCodeGenerater/tds/**",
    ], allow_empty = True),
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
swift_library(
    name = "TbParser",
    alwayslink = True,
    always_include_developer_search_paths = True,
    copts = [
        "-DSWIFT_PACKAGE",
        "-Xcc",
        "-DSWIFT_PACKAGE",
    ],
    module_name = "TbParser",
    package_name = "BuildToolPlugin",
    srcs = glob([
        "Sources/TbParser/**/*.swift",
    ], exclude = [
        "Sources/TbParser/**/*.docc/**",
        "Sources/TbParser/**/*.xcprivacy/**",
    ], allow_empty = True),
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
swift_library(
    name = "TbParserTests_library",
    alwayslink = True,
    always_include_developer_search_paths = True,
    copts = [
        "-DSWIFT_PACKAGE",
        "-Xcc",
        "-DSWIFT_PACKAGE",
    ],
    module_name = "TbParserTests",
    package_name = "BuildToolPlugin",
    srcs = glob([
        "Generated/TbParserTestsPlugin/**/*.swift",
        "Sources/TbParserTests/**/*.swift",
    ], exclude = [
        "Sources/TbParserTests/**/*.docc/**",
        "Sources/TbParserTests/**/*.xcprivacy/**",
    ], allow_empty = True),
    deps = [
        ":TbParser",
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
    name = "TbParserTests",
    deps = [
        ":TbParserTests_library",
    ],
    minimum_os_version = "13.0",
    visibility = [
        "//visibility:public",
    ],
)