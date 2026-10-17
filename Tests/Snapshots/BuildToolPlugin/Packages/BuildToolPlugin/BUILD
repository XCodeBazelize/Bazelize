load("//tools:apple_simulator_test.bzl", "apple_simulator_test")
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_unit_test")
load("@build_bazel_rules_apple//apple:macos.bzl", "macos_unit_test")
load("@build_bazel_rules_apple//apple:tvos.bzl", "tvos_unit_test")
load("@build_bazel_rules_apple//apple:visionos.bzl", "visionos_unit_test")
load("@build_bazel_rules_apple//apple:watchos.bzl", "watchos_unit_test")
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
        "-Wl,-rpath,/private/var/select/developer_dir/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/PluginAPI",
        "-Wl,-rpath,/var/db/xcode_select_link/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/PluginAPI",
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
    target_compatible_with = [
        "@platforms//os:macos",
    ],
    visibility = [
        "//visibility:public",
    ],
)
ios_unit_test(
    name = "TbParserTests_ios_simulator",
    deps = [
        ":TbParserTests_library",
    ],
    minimum_os_version = "15.0",
    target_compatible_with = [
        "@platforms//os:ios",
        "@apple_support//constraints:simulator",
    ],
    timeout = "long",
    visibility = [
        "//visibility:public",
    ],
)
ios_unit_test(
    name = "TbParserTests_ios_device_bundle_rule",
    deps = [
        ":TbParserTests_library",
    ],
    minimum_os_version = "15.0",
    tags = [
        "manual",
    ],
    target_compatible_with = [
        "@platforms//os:ios",
        "@apple_support//constraints:device",
    ],
    visibility = [
        "//visibility:private",
    ],
)
alias(
    name = "TbParserTests_ios_device_bundle",
    actual = ":TbParserTests_ios_device_bundle_rule.__internal__.__test_bundle",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
tvos_unit_test(
    name = "TbParserTests_tvos_simulator_bundle",
    deps = [
        ":TbParserTests_library",
    ],
    minimum_os_version = "15.0",
    tags = [
        "manual",
    ],
    target_compatible_with = [
        "@platforms//os:tvos",
        "@apple_support//constraints:simulator",
    ],
    visibility = [
        "//visibility:private",
    ],
)
apple_simulator_test(
    name = "TbParserTests_tvos_simulator",
    bundle = ":TbParserTests_tvos_simulator_bundle.__internal__.__test_bundle",
    destination_platform = "tvOS Simulator",
    developer_platform = "AppleTVSimulator",
    product_family = "Apple TV",
    runtime_platform = "tvOS",
    target_compatible_with = [
        "@platforms//os:tvos",
        "@apple_support//constraints:simulator",
    ],
    timeout = "long",
    visibility = [
        "//visibility:public",
    ],
)
tvos_unit_test(
    name = "TbParserTests_tvos_device_bundle_rule",
    deps = [
        ":TbParserTests_library",
    ],
    minimum_os_version = "15.0",
    tags = [
        "manual",
    ],
    target_compatible_with = [
        "@platforms//os:tvos",
        "@apple_support//constraints:device",
    ],
    visibility = [
        "//visibility:private",
    ],
)
alias(
    name = "TbParserTests_tvos_device_bundle",
    actual = ":TbParserTests_tvos_device_bundle_rule.__internal__.__test_bundle",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
watchos_unit_test(
    name = "TbParserTests_watchos_simulator_bundle",
    deps = [
        ":TbParserTests_library",
    ],
    minimum_os_version = "9.0",
    tags = [
        "manual",
    ],
    target_compatible_with = [
        "@platforms//os:watchos",
        "@apple_support//constraints:simulator",
    ],
    visibility = [
        "//visibility:private",
    ],
)
apple_simulator_test(
    name = "TbParserTests_watchos_simulator",
    bundle = ":TbParserTests_watchos_simulator_bundle.__internal__.__test_bundle",
    destination_platform = "watchOS Simulator",
    developer_platform = "WatchSimulator",
    product_family = "Apple Watch",
    runtime_platform = "watchOS",
    target_compatible_with = [
        "@platforms//os:watchos",
        "@apple_support//constraints:simulator",
    ],
    timeout = "long",
    visibility = [
        "//visibility:public",
    ],
)
watchos_unit_test(
    name = "TbParserTests_watchos_device_bundle_rule",
    deps = [
        ":TbParserTests_library",
    ],
    minimum_os_version = "9.0",
    tags = [
        "manual",
    ],
    target_compatible_with = [
        "@platforms//os:watchos",
        "@apple_support//constraints:device",
    ],
    visibility = [
        "//visibility:private",
    ],
)
alias(
    name = "TbParserTests_watchos_device_bundle",
    actual = ":TbParserTests_watchos_device_bundle_rule.__internal__.__test_bundle",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
visionos_unit_test(
    name = "TbParserTests_xros_simulator_bundle",
    deps = [
        ":TbParserTests_library",
    ],
    minimum_os_version = "1.0",
    tags = [
        "manual",
    ],
    target_compatible_with = [
        "@platforms//os:visionos",
        "@apple_support//constraints:simulator",
    ],
    visibility = [
        "//visibility:private",
    ],
)
apple_simulator_test(
    name = "TbParserTests_xros_simulator",
    bundle = ":TbParserTests_xros_simulator_bundle.__internal__.__test_bundle",
    destination_platform = "visionOS Simulator",
    developer_platform = "XRSimulator",
    product_family = "Apple Vision",
    runtime_platform = "xrOS",
    target_compatible_with = [
        "@platforms//os:visionos",
        "@apple_support//constraints:simulator",
    ],
    timeout = "long",
    visibility = [
        "//visibility:public",
    ],
)
visionos_unit_test(
    name = "TbParserTests_xros_device_bundle_rule",
    deps = [
        ":TbParserTests_library",
    ],
    minimum_os_version = "1.0",
    tags = [
        "manual",
    ],
    target_compatible_with = [
        "@platforms//os:visionos",
        "@apple_support//constraints:device",
    ],
    visibility = [
        "//visibility:private",
    ],
)
alias(
    name = "TbParserTests_xros_device_bundle",
    actual = ":TbParserTests_xros_device_bundle_rule.__internal__.__test_bundle",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)