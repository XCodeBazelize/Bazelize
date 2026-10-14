load("//tools:apple_simulator_test.bzl", "apple_simulator_test")
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_unit_test")
load("@build_bazel_rules_apple//apple:macos.bzl", "macos_unit_test")
load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_bundle", "apple_resource_group")
load("@build_bazel_rules_apple//apple:tvos.bzl", "tvos_unit_test")
load("@build_bazel_rules_apple//apple:visionos.bzl", "visionos_unit_test")
load("@build_bazel_rules_apple//apple:watchos.bzl", "watchos_unit_test")
load("@build_bazel_rules_swift//swift:swift_library.bzl", "swift_library")

apple_resource_group(
    name = "TargetResourceResourcesProcessed",
    resources = glob([
        "Sources/TargetResource/**/*.h",
        "Sources/TargetResource/**/*.lproj/**",
        "Sources/TargetResource/**/*.metal",
        "Sources/TargetResource/**/*.storyboard",
        "Sources/TargetResource/**/*.xcassets/**",
        "Sources/TargetResource/**/*.xcdatamodel/**",
        "Sources/TargetResource/**/*.xcdatamodeld/**",
        "Sources/TargetResource/**/*.xcstrings",
        "Sources/TargetResource/**/*.xib",
        "Sources/TargetResource/Assets.xcassets/**",
        "Sources/TargetResource/Base.lproj/**",
        "Sources/TargetResource/Localized/**",
        "Sources/TargetResource/Model.xcdatamodeld/**",
        "Sources/TargetResource/Processed/**",
    ], allow_empty = True),
)
apple_resource_group(
    name = "TargetResourceResourcesCopied0",
    strip_structured_resources_prefixes = [
        "Sources/TargetResource",
    ],
    structured_resources = [
        "Sources/TargetResource/single.txt",
        "Sources/TargetResource/PrivacyInfo.xcprivacy",
    ] + glob([
        "Sources/TargetResource/Copied/**",
        "Sources/TargetResource/de.lproj/**",
    ]),
)
apple_resource_bundle(
    name = "TargetResourceResources",
    bundle_name = "TargetResource_TargetResource",
    infoplists = [
        "Generated/TargetResourceResourceBundle-Info.plist",
    ],
    resources = [
        ":TargetResourceResourcesProcessed",
        ":TargetResourceResourcesCopied0",
    ],
    tags = [
        "manual",
    ],
)
swift_library(
    name = "TargetResource",
    alwayslink = True,
    always_include_developer_search_paths = True,
    copts = [
        "-DSWIFT_PACKAGE",
        "-Xcc",
        "-DSWIFT_PACKAGE",
    ],
    module_name = "TargetResource",
    package_name = "TargetResource",
    srcs = [
        "Generated/TargetResourceResourceBundleAccessor.swift",
    ] + glob([
        "Sources/TargetResource/**/*.swift",
    ], exclude = [
        "Sources/TargetResource/**/*.docc/**",
        "Sources/TargetResource/**/*.xcprivacy/**",
    ], allow_empty = True),
    data = [
        ":TargetResourceResources",
    ],
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
apple_resource_bundle(
    name = "TargetResourceTestsResources",
    bundle_name = "TargetResource_TargetResourceTests",
    infoplists = [
        "Generated/TargetResourceTestsResourceBundle-Info.plist",
    ],
    resources = glob([
        "Sources/TargetResourceTests/Fixtures/**",
    ], allow_empty = True),
    tags = [
        "manual",
    ],
)
swift_library(
    name = "TargetResourceTests_library",
    alwayslink = True,
    always_include_developer_search_paths = True,
    copts = [
        "-DSWIFT_PACKAGE",
        "-Xcc",
        "-DSWIFT_PACKAGE",
    ],
    module_name = "TargetResourceTests",
    package_name = "TargetResource",
    srcs = [
        "Generated/TargetResourceTestsResourceBundleAccessor.swift",
    ] + glob([
        "Sources/TargetResourceTests/**/*.swift",
    ], exclude = [
        "Sources/TargetResourceTests/**/*.docc/**",
        "Sources/TargetResourceTests/**/*.xcprivacy/**",
    ], allow_empty = True),
    deps = [
        ":TargetResource",
    ],
    data = [
        ":TargetResourceTestsResources",
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
    name = "TargetResourceTests",
    deps = [
        ":TargetResourceTests_library",
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
    name = "TargetResourceTests_ios_simulator",
    deps = [
        ":TargetResourceTests_library",
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
    name = "TargetResourceTests_ios_device_bundle_rule",
    deps = [
        ":TargetResourceTests_library",
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
    name = "TargetResourceTests_ios_device_bundle",
    actual = ":TargetResourceTests_ios_device_bundle_rule.__internal__.__test_bundle",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
tvos_unit_test(
    name = "TargetResourceTests_tvos_simulator_bundle",
    deps = [
        ":TargetResourceTests_library",
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
    name = "TargetResourceTests_tvos_simulator",
    bundle = ":TargetResourceTests_tvos_simulator_bundle.__internal__.__test_bundle",
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
    name = "TargetResourceTests_tvos_device_bundle_rule",
    deps = [
        ":TargetResourceTests_library",
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
    name = "TargetResourceTests_tvos_device_bundle",
    actual = ":TargetResourceTests_tvos_device_bundle_rule.__internal__.__test_bundle",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
watchos_unit_test(
    name = "TargetResourceTests_watchos_simulator_bundle",
    deps = [
        ":TargetResourceTests_library",
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
    name = "TargetResourceTests_watchos_simulator",
    bundle = ":TargetResourceTests_watchos_simulator_bundle.__internal__.__test_bundle",
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
    name = "TargetResourceTests_watchos_device_bundle_rule",
    deps = [
        ":TargetResourceTests_library",
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
    name = "TargetResourceTests_watchos_device_bundle",
    actual = ":TargetResourceTests_watchos_device_bundle_rule.__internal__.__test_bundle",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
visionos_unit_test(
    name = "TargetResourceTests_xros_simulator_bundle",
    deps = [
        ":TargetResourceTests_library",
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
    name = "TargetResourceTests_xros_simulator",
    bundle = ":TargetResourceTests_xros_simulator_bundle.__internal__.__test_bundle",
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
    name = "TargetResourceTests_xros_device_bundle_rule",
    deps = [
        ":TargetResourceTests_library",
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
    name = "TargetResourceTests_xros_device_bundle",
    actual = ":TargetResourceTests_xros_device_bundle_rule.__internal__.__test_bundle",
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)