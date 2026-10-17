//
//  PluginApple.swift
//
//
//  Created by Yume on 2023/2/3.
//

import Foundation

// MARK: - PluginApple

/// https://github.com/bazelbuild/rules_apple
final class PluginApple: PluginBuiltin {
    let dep: BazelDep.Apple = .latest

    override func module(_ builder: CodeBuilder) {
        builder.bazel_dep(
            name: "rules_apple",
            version: dep.rawValue,
            repo_name: "build_bazel_rules_apple")
        builder.custom("""
        register_toolchains(
            "//:tvos_simulator_test_toolchain",
            "//:visionos_simulator_test_toolchain",
            "//:watchos_simulator_test_toolchain",
        )
        """)
    }

    /// Simulator tests compile for an Apple target platform but execute
    /// `xcodebuild` on the macOS host. Bazel's default test toolchain otherwise
    /// requires the target platform itself to be an execution platform.
    override func build(_ builder: CodeBuilder) {
        builder.custom("""
        toolchain(
            name = "tvos_simulator_test_toolchain",
            exec_compatible_with = ["@platforms//os:macos"],
            target_compatible_with = [
                "@platforms//os:tvos",
                "@apple_support//constraints:simulator",
            ],
            toolchain = "@bazel_tools//tools/test:empty_toolchain",
            toolchain_type = "@bazel_tools//tools/test:default_test_toolchain_type",
        )
        toolchain(
            name = "visionos_simulator_test_toolchain",
            exec_compatible_with = ["@platforms//os:macos"],
            target_compatible_with = [
                "@platforms//os:visionos",
                "@apple_support//constraints:simulator",
            ],
            toolchain = "@bazel_tools//tools/test:empty_toolchain",
            toolchain_type = "@bazel_tools//tools/test:default_test_toolchain_type",
        )
        toolchain(
            name = "watchos_simulator_test_toolchain",
            exec_compatible_with = ["@platforms//os:macos"],
            target_compatible_with = [
                "@platforms//os:watchos",
                "@apple_support//constraints:simulator",
            ],
            toolchain = "@bazel_tools//tools/test:empty_toolchain",
            toolchain_type = "@bazel_tools//tools/test:default_test_toolchain_type",
        )
        """)
    }
}
