load("@bazel_skylib//lib:selects.bzl", "selects")

filegroup(
    name = "plugins",
    # srcs = None,
    visibility = [
        "//visibility:public",
    ],
)

config_setting(
    name = "swiftpm_debug_dbg",
    values = {
        "compilation_mode": "dbg",
    },
)

config_setting(
    name = "swiftpm_debug_fastbuild",
    values = {
        "compilation_mode": "fastbuild",
    },
)

selects.config_setting_group(
    name = "swiftpm_debug",
    match_any = [
        ":swiftpm_debug_dbg",
        ":swiftpm_debug_fastbuild",
    ],
)

selects.config_setting_group(
    name = "swiftpm_platform_ios",
    match_any = [
        "//Packages:swiftpm_platform_ios_device",
        "//Packages:swiftpm_platform_ios_simulator",
    ],
)

selects.config_setting_group(
    name = "swiftpm_platform_ios_or_maccatalyst_or_macos_or_tvos_or_visionos_or_watchos",
    match_any = [
        "//Packages:swiftpm_platform_ios",
        "//Packages:swiftpm_platform_maccatalyst",
        "@platforms//os:macos",
        "@platforms//os:tvos",
        "@platforms//os:visionos",
        "@platforms//os:watchos",
    ],
)

selects.config_setting_group(
    name = "condition_Platform_platform_ios_and_configuration_debug",
    match_all = [
        "//Packages:swiftpm_platform_ios",
        "//Packages:swiftpm_debug",
    ],
)

selects.config_setting_group(
    name = "swiftpm_platform_ios_device",
    match_all = [
        "@platforms//os:ios",
        "@apple_support//constraints:device",
    ],
)

selects.config_setting_group(
    name = "swiftpm_platform_ios_simulator",
    match_all = [
        "@platforms//os:ios",
        "@apple_support//constraints:simulator",
    ],
)

selects.config_setting_group(
    name = "swiftpm_platform_maccatalyst",
    match_all = [
        "@platforms//os:ios",
        "@apple_support//constraints:catalyst",
    ],
)
