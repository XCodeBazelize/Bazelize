load("@build_bazel_rules_apple//apple:ios.bzl", "ios_unit_test")
load("@build_bazel_rules_apple//apple:macos.bzl", "macos_unit_test")
load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_bundle")
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
        "//Packages:swiftpm_platform_ios_or_macos": [
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
        "//conditions:default": [],
        "@platforms//os:ios": [
            "-DIOS_PLATFORM",
            "-Xcc",
            "-DIOS_PLATFORM",
        ],
    }) + select({
        "//Packages:condition_Platform_platform_ios_and_configuration_debug": [
            "-DIOS_DEBUG",
            "-Xcc",
            "-DIOS_DEBUG",
        ],
        "//conditions:default": [],
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
        "//conditions:default": [],
        "@platforms//os:ios": [
            ":IOSOnly",
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
    visibility = [
        "//visibility:public",
    ],
)