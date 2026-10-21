load("@build_bazel_rules_apple//apple:ios.bzl", "ios_unit_test")
load("@build_bazel_rules_apple//apple:macos.bzl", "macos_unit_test")
load("@build_bazel_rules_apple//apple:tvos.bzl", "tvos_unit_test")
load("@build_bazel_rules_apple//apple:visionos.bzl", "visionos_unit_test")
load("@build_bazel_rules_apple//apple:watchos.bzl", "watchos_unit_test")
load("@build_bazel_rules_swift//swift:swift_binary.bzl", "swift_binary")
load("@build_bazel_rules_swift//swift:swift_library.bzl", "swift_library")
load("//tools:apple_simulator_test.bzl", "apple_simulator_test")

swift_binary(
    name = "GeneratePrebuild",
    srcs = glob([
        "Sources/GeneratePrebuild/**/*.swift",
    ]),
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
    module_name = "GeneratePrebuild",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)

swift_library(
    name = "PrebuildPlugin",
    package_name = "PrebuildPlugin",
    srcs = glob(
        [
            "Generated/PrebuildPluginPlugin/**/*.swift",
            "Sources/PrebuildPlugin/**/*.swift",
        ],
        allow_empty = True,
        exclude = [
            "Sources/PrebuildPlugin/**/*.docc/**",
            "Sources/PrebuildPlugin/**/*.xcprivacy/**",
        ],
    ),
    always_include_developer_search_paths = True,
    copts = [
        "-DSWIFT_PACKAGE",
        "-Xcc",
        "-DSWIFT_PACKAGE",
    ],
    module_name = "PrebuildPlugin",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
    alwayslink = True,
)

swift_library(
    name = "PrebuildPluginTests_library",
    package_name = "PrebuildPlugin",
    testonly = True,
    srcs = glob(
        [
            "Sources/PrebuildPluginTests/**/*.swift",
        ],
        allow_empty = True,
        exclude = [
            "Sources/PrebuildPluginTests/**/*.docc/**",
            "Sources/PrebuildPluginTests/**/*.xcprivacy/**",
        ],
    ),
    always_include_developer_search_paths = True,
    copts = [
        "-DSWIFT_PACKAGE",
        "-Xcc",
        "-DSWIFT_PACKAGE",
    ],
    module_name = "PrebuildPluginTests",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:private",
    ],
    deps = [
        ":PrebuildPlugin",
    ],
    alwayslink = True,
)

macos_unit_test(
    name = "PrebuildPluginTests",
    minimum_os_version = "12.0",
    target_compatible_with = [
        "@platforms//os:macos",
    ],
    visibility = [
        "//visibility:public",
    ],
    deps = [
        ":PrebuildPluginTests_library",
    ],
)

ios_unit_test(
    name = "PrebuildPluginTests_ios_simulator",
    timeout = "long",
    minimum_os_version = "15.0",
    target_compatible_with = [
        "@platforms//os:ios",
        "@apple_support//constraints:simulator",
    ],
    visibility = [
        "//visibility:public",
    ],
    deps = [
        ":PrebuildPluginTests_library",
    ],
)

ios_unit_test(
    name = "PrebuildPluginTests_ios_device_bundle_rule",
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
    deps = [
        ":PrebuildPluginTests_library",
    ],
)

alias(
    name = "PrebuildPluginTests_ios_device_bundle",
    actual = ":PrebuildPluginTests_ios_device_bundle_rule.__internal__.__test_bundle",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)

tvos_unit_test(
    name = "PrebuildPluginTests_tvos_simulator_bundle",
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
    deps = [
        ":PrebuildPluginTests_library",
    ],
)

apple_simulator_test(
    name = "PrebuildPluginTests_tvos_simulator",
    timeout = "long",
    bundle = ":PrebuildPluginTests_tvos_simulator_bundle.__internal__.__test_bundle",
    destination_platform = "tvOS Simulator",
    developer_platform = "AppleTVSimulator",
    product_family = "Apple TV",
    runtime_platform = "tvOS",
    target_compatible_with = [
        "@platforms//os:tvos",
        "@apple_support//constraints:simulator",
    ],
    visibility = [
        "//visibility:public",
    ],
)

tvos_unit_test(
    name = "PrebuildPluginTests_tvos_device_bundle_rule",
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
    deps = [
        ":PrebuildPluginTests_library",
    ],
)

alias(
    name = "PrebuildPluginTests_tvos_device_bundle",
    actual = ":PrebuildPluginTests_tvos_device_bundle_rule.__internal__.__test_bundle",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)

watchos_unit_test(
    name = "PrebuildPluginTests_watchos_simulator_bundle",
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
    deps = [
        ":PrebuildPluginTests_library",
    ],
)

apple_simulator_test(
    name = "PrebuildPluginTests_watchos_simulator",
    timeout = "long",
    bundle = ":PrebuildPluginTests_watchos_simulator_bundle.__internal__.__test_bundle",
    destination_platform = "watchOS Simulator",
    developer_platform = "WatchSimulator",
    product_family = "Apple Watch",
    runtime_platform = "watchOS",
    target_compatible_with = [
        "@platforms//os:watchos",
        "@apple_support//constraints:simulator",
    ],
    visibility = [
        "//visibility:public",
    ],
)

watchos_unit_test(
    name = "PrebuildPluginTests_watchos_device_bundle_rule",
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
    deps = [
        ":PrebuildPluginTests_library",
    ],
)

alias(
    name = "PrebuildPluginTests_watchos_device_bundle",
    actual = ":PrebuildPluginTests_watchos_device_bundle_rule.__internal__.__test_bundle",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)

visionos_unit_test(
    name = "PrebuildPluginTests_xros_simulator_bundle",
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
    deps = [
        ":PrebuildPluginTests_library",
    ],
)

apple_simulator_test(
    name = "PrebuildPluginTests_xros_simulator",
    timeout = "long",
    bundle = ":PrebuildPluginTests_xros_simulator_bundle.__internal__.__test_bundle",
    destination_platform = "visionOS Simulator",
    developer_platform = "XRSimulator",
    product_family = "Apple Vision",
    runtime_platform = "xrOS",
    target_compatible_with = [
        "@platforms//os:visionos",
        "@apple_support//constraints:simulator",
    ],
    visibility = [
        "//visibility:public",
    ],
)

visionos_unit_test(
    name = "PrebuildPluginTests_xros_device_bundle_rule",
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
    deps = [
        ":PrebuildPluginTests_library",
    ],
)

alias(
    name = "PrebuildPluginTests_xros_device_bundle",
    actual = ":PrebuildPluginTests_xros_device_bundle_rule.__internal__.__test_bundle",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
