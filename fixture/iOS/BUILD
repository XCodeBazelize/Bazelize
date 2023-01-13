# Generated using Bazelize 0.0.3 - https://github.com/XCodeBazelize/Bazelize

load("@bazel_skylib//rules:common_settings.bzl", "string_flag")

string_flag(
    name = "mode",
    build_setting_default = "Debug",
)

config_setting(
    name = "Debug",
    flag_values = {
        ":mode": "Debug"
    },
)

config_setting(
    name = "Release",
    flag_values = {
        ":mode": "Release"
    },
)