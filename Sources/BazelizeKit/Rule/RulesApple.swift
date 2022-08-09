//
//  RulesApple.swift
//
//
//  Created by Yume on 2022/7/1.
//

import Foundation

/// https://github.com/bazelbuild/rules_apple/tree/master/doc
enum RulesApple {
    enum IOS: String, LoadableRule {
        static let target = "@build_bazel_rules_apple//apple:ios.bzl"

        case ios_application
        case ios_app_clip
        case ios_extension
        case ios_imessage_application
        case ios_imessage_extension
        case ios_sticker_pack_extension
        case ios_framework
        case ios_static_framework
        case ios_dynamic_framework

        case ios_ui_test
        case ios_ui_test_suite
        case ios_unit_test
        case ios_unit_test_suite
        case ios_build_test
    }

    enum Mac: String, LoadableRule {
        static let target = "@build_bazel_rules_apple//apple:macos.bzl"

        case macos_application
        case macos_bundle
        case macos_command_line_application
        case macos_extension

        case macos_unit_test
        case macos_build_test

        case macos_dylib
        case macos_kernel_extension
        case macos_quick_look_plugin
        case macos_spotlight_importer
        case macos_xpc_service
    }

    enum TV: String, LoadableRule {
        static let target = "@build_bazel_rules_apple//apple:tvos.bzl"

        case tvos_application
        case tvos_extension
        case tvos_static_framework
        case tvos_dynamic_framework
        case tvos_ui_test
        case tvos_unit_test
        case tvos_build_test
    }

    enum Watch: String, LoadableRule {
        static let target = "@build_bazel_rules_apple//apple:watchos.bzl"

        case watchos_application
        case watchos_extension
        case watchos_static_framework
        case watchos_dynamic_framework
        case watchos_ui_test
        case watchos_unit_test
        case watchos_build_test
    }

    enum Verion: String, LoadableRule {
        static let target = "@build_bazel_rules_apple//apple:versioning.bzl"

        case apple_bundle_version
    }

    enum Apple: String, LoadableRule {
        static let target = "@build_bazel_rules_apple//apple:apple.bzl"

        case apple_dynamic_framework_import
        case apple_dynamic_xcframework_import
        case apple_static_framework_import
        case apple_static_xcframework
        case apple_static_xcframework_import
        case apple_universal_binary
        case apple_xcframework
        case local_provisioning_profile
        case provisioning_profile_repository
    }

    enum Resource: String, LoadableRule {
        static let target = "@build_bazel_rules_apple//apple:resources.bzl"

        case apple_bundle_import
        case apple_core_data_model
        case apple_core_ml_library
        case apple_resource_bundle
        case apple_resource_group
        case swift_apple_core_ml_library
        case swift_intent_library
    }
}



// options
// https://github.com/bazelbuild/rules_apple/blob/master/doc/common_info.md
