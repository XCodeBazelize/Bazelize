# Generated using Bazelize 0.0.5 - https://github.com/XCodeBazelize/Bazelize

load("@bazel_skylib//rules:common_settings.bzl", "string_flag")
load("@build_bazel_rules_swift//swift:swift_binary.bzl", "swift_binary")
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")
load("@rules_xcodeproj//xcodeproj:defs.bzl", "xcodeproj")

string_flag(
    name = "mode",
    build_setting_default = "Debug",
    values = [
        "Debug",
        "Release",
    ],
)
config_setting(
    name = "Debug",
    flag_values = {
        ":mode": "Debug",
    },
)
config_setting(
    name = "Release",
    flag_values = {
        ":mode": "Release",
    },
)
sh_binary(
    name = "lint",
    srcs = [
        "lint.sh",
    ],
)
swift_binary(
    name = "_plugin_host",
    srcs = [
        "plugin-host.swift",
    ],
    tags = [
        "manual",
    ],
    visibility = [
        "//visibility:public",
    ],
)
sh_binary(
    name = "plugins",
    srcs = [
        "plugins.sh",
    ],
    data = [
        ":_plugin_host",
        "plugin-plan.json",
        "//Packages:plugins",
    ],
)
xcodeproj(
    name = "xcodeproj",
    project_name = "Example",
    tags = [
        "manual",
    ],
    top_level_targets = [
        "//Targets/Example:Example",
        "//Targets/ExampleTests:ExampleTests",
        "//Targets/ExampleUITests:ExampleUITests",
        "//Targets/Framework1:Framework1",
        "//Targets/Framework1Tests:Framework1Tests",
        "//Targets/Framework2:Framework2",
        "//Targets/Framework2Tests:Framework2Tests",
        "//Targets/Framework3:Framework3",
        "//Targets/Framework3Tests:Framework3Tests",
        "//Targets/Static:Static",
        "//Targets/Static2:Static2",
        "//Targets/StaticFramework1:StaticFramework1",
    ],
)