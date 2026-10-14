load("//tools:apple_simulator_test.bzl", "apple_simulator_test")
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_unit_test")
load("@build_bazel_rules_apple//apple:macos.bzl", "macos_unit_test")
load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_bundle")
load("@build_bazel_rules_apple//apple:tvos.bzl", "tvos_unit_test")
load("@build_bazel_rules_apple//apple:visionos.bzl", "visionos_unit_test")
load("@build_bazel_rules_apple//apple:watchos.bzl", "watchos_unit_test")
load("@build_bazel_rules_swift//swift:swift_library.bzl", "swift_library")

swift_library(
    name = "Platform",
    alwayslink = True,
    always_include_developer_search_paths = True,
    copts = [
        "-DSWIFT_PACKAGE",
        "-Xcc",
        "-DSWIFT_PACKAGE",
    ] + select({
        "//Packages:swiftpm_platform_ios_or_maccatalyst_or_macos_or_tvos_or_visionos_or_watchos": [
            "-DAPPLE_PLATFORM",
            "-Xcc",
            "-DAPPLE_PLATFORM",
        ],
        "//conditions:default": [],
    }) + select({
        "//conditions:default": [],
        "@platforms//os:macos": [
            "-DMACOS_PLATFORM",
            "-Xcc",
            "-DMACOS_PLATFORM",
        ],
    }) + select({
        "//Packages:swiftpm_platform_maccatalyst": [
            "-DMACCATALYST_PLATFORM",
            "-Xcc",
            "-DMACCATALYST_PLATFORM",
        ],
        "//conditions:default": [],
    }) + select({
        "//Packages:swiftpm_platform_ios": [
            "-DIOS_PLATFORM",
            "-Xcc",
            "-DIOS_PLATFORM",
        ],
        "//conditions:default": [],
    }) + select({
        "//Packages:condition_Platform_platform_ios_and_configuration_debug": [
            "-DIOS_DEBUG",
            "-Xcc",
            "-DIOS_DEBUG",
        ],
        "//conditions:default": [],
    }) + select({
        "//conditions:default": [],
        "@platforms//os:tvos": [
            "-DTVOS_PLATFORM",
            "-Xcc",
            "-DTVOS_PLATFORM",
        ],
    }) + select({
        "//conditions:default": [],
        "@platforms//os:watchos": [
            "-DWATCHOS_PLATFORM",
            "-Xcc",
            "-DWATCHOS_PLATFORM",
        ],
    }) + select({
        "//conditions:default": [],
        "@platforms//os:visionos": [
            "-DVISIONOS_PLATFORM",
            "-Xcc",
            "-DVISIONOS_PLATFORM",
        ],
    }) + select({
        "//conditions:default": [],
        "@platforms//os:linux": [
            "-DLINUX_PLATFORM",
            "-Xcc",
            "-DLINUX_PLATFORM",
        ],
    }) + select({
        "//conditions:default": [],
        "@platforms//os:windows": [
            "-DWINDOWS_PLATFORM",
            "-Xcc",
            "-DWINDOWS_PLATFORM",
        ],
    }),
    module_name = "Platform",
    package_name = "Platform",
    srcs = glob([
        "Sources/Platform/**/*.swift",
    ], exclude = [
        "Sources/Platform/**/*.docc/**",
        "Sources/Platform/**/*.xcprivacy/**",
    ], allow_empty = True),
    deps = select({
        "//Packages:swiftpm_platform_ios": [
            ":IOSOnly",
        ],
        "//conditions:default": [],
    }) + select({
        "//Packages:swiftpm_platform_maccatalyst": [
            ":MacCatalystOnly",
        ],
        "//conditions:default": [],
    }) + select({
        "//conditions:default": [],
        "@platforms//os:tvos": [
            ":TVOSOnly",
        ],
    }) + select({
        "//conditions:default": [],
        "@platforms//os:visionos": [
            ":VisionOSOnly",
        ],
    }) + select({
        "//conditions:default": [],
        "@platforms//os:watchos": [
            ":WatchOSOnly",
        ],
    }),
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
swift_library(
    name = "IOSOnly",
    alwayslink = True,
    always_include_developer_search_paths = True,
    copts = [
        "-DSWIFT_PACKAGE",
        "-Xcc",
        "-DSWIFT_PACKAGE",
    ],
    module_name = "IOSOnly",
    package_name = "Platform",
    srcs = glob([
        "Sources/IOSOnly/**/*.swift",
    ], exclude = [
        "Sources/IOSOnly/**/*.docc/**",
        "Sources/IOSOnly/**/*.xcprivacy/**",
    ], allow_empty = True),
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
swift_library(
    name = "MacCatalystOnly",
    alwayslink = True,
    always_include_developer_search_paths = True,
    copts = [
        "-DSWIFT_PACKAGE",
        "-Xcc",
        "-DSWIFT_PACKAGE",
    ],
    module_name = "MacCatalystOnly",
    package_name = "Platform",
    srcs = glob([
        "Sources/MacCatalystOnly/**/*.swift",
    ], exclude = [
        "Sources/MacCatalystOnly/**/*.docc/**",
        "Sources/MacCatalystOnly/**/*.xcprivacy/**",
    ], allow_empty = True),
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
swift_library(
    name = "TVOSOnly",
    alwayslink = True,
    always_include_developer_search_paths = True,
    copts = [
        "-DSWIFT_PACKAGE",
        "-Xcc",
        "-DSWIFT_PACKAGE",
    ],
    module_name = "TVOSOnly",
    package_name = "Platform",
    srcs = glob([
        "Sources/TVOSOnly/**/*.swift",
    ], exclude = [
        "Sources/TVOSOnly/**/*.docc/**",
        "Sources/TVOSOnly/**/*.xcprivacy/**",
    ], allow_empty = True),
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
swift_library(
    name = "VisionOSOnly",
    alwayslink = True,
    always_include_developer_search_paths = True,
    copts = [
        "-DSWIFT_PACKAGE",
        "-Xcc",
        "-DSWIFT_PACKAGE",
    ],
    module_name = "VisionOSOnly",
    package_name = "Platform",
    srcs = glob([
        "Sources/VisionOSOnly/**/*.swift",
    ], exclude = [
        "Sources/VisionOSOnly/**/*.docc/**",
        "Sources/VisionOSOnly/**/*.xcprivacy/**",
    ], allow_empty = True),
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
swift_library(
    name = "WatchOSOnly",
    alwayslink = True,
    always_include_developer_search_paths = True,
    copts = [
        "-DSWIFT_PACKAGE",
        "-Xcc",
        "-DSWIFT_PACKAGE",
    ],
    module_name = "WatchOSOnly",
    package_name = "Platform",
    srcs = glob([
        "Sources/WatchOSOnly/**/*.swift",
    ], exclude = [
        "Sources/WatchOSOnly/**/*.docc/**",
        "Sources/WatchOSOnly/**/*.xcprivacy/**",
    ], allow_empty = True),
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
apple_resource_bundle(
    name = "PlatformTestsResources",
    bundle_name = "Platform_PlatformTests",
    infoplists = [
        "Generated/PlatformTestsResourceBundle-Info.plist",
    ],
    resources = glob([
        "Sources/PlatformTests/Fixtures/**",
    ], allow_empty = True),
    tags = [
        "manual",
    ],
)
swift_library(
    name = "PlatformTests_library",
    alwayslink = True,
    always_include_developer_search_paths = True,
    copts = [
        "-DSWIFT_PACKAGE",
        "-Xcc",
        "-DSWIFT_PACKAGE",
    ],
    module_name = "PlatformTests",
    package_name = "Platform",
    srcs = [
        "Generated/PlatformTestsResourceBundleAccessor.swift",
    ] + glob([
        "Sources/PlatformTests/**/*.swift",
    ], exclude = [
        "Sources/PlatformTests/**/*.docc/**",
        "Sources/PlatformTests/**/*.xcprivacy/**",
    ], allow_empty = True),
    deps = [
        ":Platform",
    ],
    data = [
        ":PlatformTestsResources",
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
    name = "PlatformTests",
    deps = [
        ":PlatformTests_library",
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
    name = "PlatformTests_ios_simulator",
    deps = [
        ":PlatformTests_library",
    ],
    minimum_os_version = "16.0",
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
    name = "PlatformTests_ios_device_bundle_rule",
    deps = [
        ":PlatformTests_library",
    ],
    minimum_os_version = "16.0",
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
    name = "PlatformTests_ios_device_bundle",
    actual = ":PlatformTests_ios_device_bundle_rule.__internal__.__test_bundle",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
tvos_unit_test(
    name = "PlatformTests_tvos_simulator_bundle",
    deps = [
        ":PlatformTests_library",
    ],
    minimum_os_version = "16.0",
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
    name = "PlatformTests_tvos_simulator",
    bundle = ":PlatformTests_tvos_simulator_bundle.__internal__.__test_bundle",
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
    name = "PlatformTests_tvos_device_bundle_rule",
    deps = [
        ":PlatformTests_library",
    ],
    minimum_os_version = "16.0",
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
    name = "PlatformTests_tvos_device_bundle",
    actual = ":PlatformTests_tvos_device_bundle_rule.__internal__.__test_bundle",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
watchos_unit_test(
    name = "PlatformTests_watchos_simulator_bundle",
    deps = [
        ":PlatformTests_library",
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
    name = "PlatformTests_watchos_simulator",
    bundle = ":PlatformTests_watchos_simulator_bundle.__internal__.__test_bundle",
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
    name = "PlatformTests_watchos_device_bundle_rule",
    deps = [
        ":PlatformTests_library",
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
    name = "PlatformTests_watchos_device_bundle",
    actual = ":PlatformTests_watchos_device_bundle_rule.__internal__.__test_bundle",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
visionos_unit_test(
    name = "PlatformTests_xros_simulator_bundle",
    deps = [
        ":PlatformTests_library",
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
    name = "PlatformTests_xros_simulator",
    bundle = ":PlatformTests_xros_simulator_bundle.__internal__.__test_bundle",
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
    name = "PlatformTests_xros_device_bundle_rule",
    deps = [
        ":PlatformTests_library",
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
    name = "PlatformTests_xros_device_bundle",
    actual = ":PlatformTests_xros_device_bundle_rule.__internal__.__test_bundle",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)