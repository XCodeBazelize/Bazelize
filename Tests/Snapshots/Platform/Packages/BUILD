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
    name = "swiftpm_platform_ios_or_macos",
    match_any = [
        "@platforms//os:ios",
        "@platforms//os:macos",
    ],
)
selects.config_setting_group(
    name = "condition_Platform_platform_ios_and_configuration_debug",
    match_all = [
        "@platforms//os:ios",
        "//Packages:swiftpm_debug",
    ],
)