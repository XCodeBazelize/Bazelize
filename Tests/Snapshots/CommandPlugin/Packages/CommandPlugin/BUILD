load("//tools:apple_simulator_test.bzl", "apple_simulator_test")
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_unit_test")
load("@build_bazel_rules_apple//apple:macos.bzl", "macos_unit_test")
load("@build_bazel_rules_apple//apple:tvos.bzl", "tvos_unit_test")
load("@build_bazel_rules_apple//apple:visionos.bzl", "visionos_unit_test")
load("@build_bazel_rules_apple//apple:watchos.bzl", "watchos_unit_test")
load("@build_bazel_rules_swift//swift:swift_binary.bzl", "swift_binary")
load("@build_bazel_rules_swift//swift:swift_library.bzl", "swift_library")
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")

swift_binary(
    name = "Hello_plugin",
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
    module_name = "Hello",
    srcs = glob([
        "Sources/Hello/**/*.swift",
    ]),
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
sh_binary(
    name = "hello_command",
    srcs = [
        "Generated/hello.sh",
    ],
    data = [
        ":Hello_plugin",
        "Generated/HelloCommand.json",
        "//:_plugin_host",
    ],
    tags = [
        "manual",
    ],
)
swift_library(
    name = "Greeting",
    alwayslink = True,
    always_include_developer_search_paths = True,
    copts = [
        "-DSWIFT_PACKAGE",
        "-Xcc",
        "-DSWIFT_PACKAGE",
    ],
    module_name = "Greeting",
    package_name = "CommandPlugin",
    srcs = glob([
        "Sources/Greeting/**/*.swift",
    ], exclude = [
        "Sources/Greeting/**/*.docc/**",
        "Sources/Greeting/**/*.xcprivacy/**",
    ], allow_empty = True),
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
swift_binary(
    name = "HelloTool",
    copts = [
        "-DSWIFT_PACKAGE",
        "-Xcc",
        "-DSWIFT_PACKAGE",
    ],
    module_name = "HelloTool",
    srcs = glob([
        "Sources/HelloTool/**/*.swift",
    ], exclude = [
        "Sources/HelloTool/**/*.docc/**",
        "Sources/HelloTool/**/*.xcprivacy/**",
    ], allow_empty = True),
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
swift_library(
    name = "GreetingTests_library",
    alwayslink = True,
    always_include_developer_search_paths = True,
    copts = [
        "-DSWIFT_PACKAGE",
        "-Xcc",
        "-DSWIFT_PACKAGE",
    ],
    module_name = "GreetingTests",
    package_name = "CommandPlugin",
    srcs = glob([
        "Sources/GreetingTests/**/*.swift",
    ], exclude = [
        "Sources/GreetingTests/**/*.docc/**",
        "Sources/GreetingTests/**/*.xcprivacy/**",
    ], allow_empty = True),
    deps = [
        ":Greeting",
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
    name = "GreetingTests",
    deps = [
        ":GreetingTests_library",
    ],
    minimum_os_version = "12.0",
    target_compatible_with = [
        "@platforms//os:macos",
    ],
    visibility = [
        "//visibility:public",
    ],
)
ios_unit_test(
    name = "GreetingTests_ios_simulator",
    deps = [
        ":GreetingTests_library",
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
    name = "GreetingTests_ios_device_bundle_rule",
    deps = [
        ":GreetingTests_library",
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
    name = "GreetingTests_ios_device_bundle",
    actual = ":GreetingTests_ios_device_bundle_rule.__internal__.__test_bundle",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
tvos_unit_test(
    name = "GreetingTests_tvos_simulator_bundle",
    deps = [
        ":GreetingTests_library",
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
    name = "GreetingTests_tvos_simulator",
    bundle = ":GreetingTests_tvos_simulator_bundle.__internal__.__test_bundle",
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
    name = "GreetingTests_tvos_device_bundle_rule",
    deps = [
        ":GreetingTests_library",
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
    name = "GreetingTests_tvos_device_bundle",
    actual = ":GreetingTests_tvos_device_bundle_rule.__internal__.__test_bundle",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
watchos_unit_test(
    name = "GreetingTests_watchos_simulator_bundle",
    deps = [
        ":GreetingTests_library",
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
    name = "GreetingTests_watchos_simulator",
    bundle = ":GreetingTests_watchos_simulator_bundle.__internal__.__test_bundle",
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
    name = "GreetingTests_watchos_device_bundle_rule",
    deps = [
        ":GreetingTests_library",
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
    name = "GreetingTests_watchos_device_bundle",
    actual = ":GreetingTests_watchos_device_bundle_rule.__internal__.__test_bundle",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
visionos_unit_test(
    name = "GreetingTests_xros_simulator_bundle",
    deps = [
        ":GreetingTests_library",
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
    name = "GreetingTests_xros_simulator",
    bundle = ":GreetingTests_xros_simulator_bundle.__internal__.__test_bundle",
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
    name = "GreetingTests_xros_device_bundle_rule",
    deps = [
        ":GreetingTests_library",
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
    name = "GreetingTests_xros_device_bundle",
    actual = ":GreetingTests_xros_device_bundle_rule.__internal__.__test_bundle",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
alias(
    name = "hello",
    actual = ":HelloTool",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)