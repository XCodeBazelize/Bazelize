# Generated using Bazelize 0.0.3 - https://github.com/XCodeBazelize/Bazelize

load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:defs.bzl",
    "top_level_target",
    "xcodeproj",
)
load("@bazel_gazelle//:def.bzl", "gazelle", "gazelle_binary")
load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@bazel_skylib//rules:common_settings.bzl", "string_flag")
load("@build_bazel_rules_apple//apple:apple.bzl", "apple_dynamic_xcframework_import")
load("@cgrindel_swift_bazel//swiftpkg:defs.bzl", "swift_update_packages")

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

# Ignore the `.build` folder that is created by running Swift package manager
# commands. The Swift Gazelle plugin executes some Swift package manager
# commands to resolve external dependencies. This results in a `.build` file
# being created.
# NOTE: Swift package manager is not used to build any of the external packages.
# The `.build` directory should be ignored. Be sure to configure your source
# control to ignore it (i.e., add it to your `.gitignore`).
# gazelle:exclude .build

# This declaration builds a Gazelle binary that incorporates all of the Gazelle
# plugins for the languages that you use in your workspace. In this example, we
# are using the Gazelle plugin for Starlark from bazel_skylib and the Gazelle
# plugin for Swift from cgrindel_swift_bazel.
gazelle_binary(
    name = "gazelle_bin",
    languages = [
        "@bazel_skylib//gazelle/bzl",
        "@cgrindel_swift_bazel//gazelle",
    ],
)

# This macro defines two targets: `swift_update_pkgs` and
# `swift_update_pkgs_to_latest`.
#
# The `swift_update_pkgs` target should be run whenever the list of external
# dependencies is updated in the `Package.swift`. Running this target will
# populate the `swift_deps.bzl` with `swift_package` declarations for all of
# the direct and transitive Swift packages that your project uses.
#
# The `swift_update_pkgs_to_latest` target should be run when you want to
# update your Swift dependencies to their latest eligible version.
swift_update_packages(
    name = "swift_update_pkgs",
    gazelle = ":gazelle_bin",
)

# This target updates the Bazel build files for your project. Run this target
# whenever you add or remove source files from your project.
gazelle(
    name = "update_build_files",
    gazelle = ":gazelle_bin",
)

bzl_library(
    name = "swift_deps",
    srcs = ["swift_deps.bzl"],
    visibility = ["//visibility:public"],
    deps = ["@cgrindel_swift_bazel//swiftpkg:defs"],
)

# Xcode
xcodeproj(
    name = "xcodeproj",
    # Custom Project Name
    project_name = "App",
    tags = ["manual"],
    top_level_targets = [
        # main target, maybe some `ios_application`
        top_level_target(":App", target_environments = ["device", "simulator"]),
        # all other target
        "//Example:Example",
        "//ExampleTests:ExampleTests",
        "//ExampleUITests:ExampleUITests",
        "//Framework1:Framework1",
        "//Framework1Tests:Framework1Tests",
        "//Framework2:Framework2",
        "//Framework2Tests:Framework2Tests",
        "//Framework3:Framework3",
        "//Framework3Tests:Framework3Tests",
        "//Static:Static",
        "//Static2:Static2",
    ],
)

apple_dynamic_xcframework_import(
    name = "SVProgressHUD",
    xcframework_imports = glob([
        "SVProgressHUD.xcframework/**",
    ]),
    visibility = [
        "//visibility:public",
    ],
)