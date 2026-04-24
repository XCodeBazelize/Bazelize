//
//  Rules+Apple.swift
//
//
//  Created by Yume on 2022/7/1.
//

import Foundation
import RuleBuilder

// MARK: - Rules.Apple

/// https://github.com/bazelbuild/rules_apple/tree/main/doc
extension Rules {
    public enum Apple {
        // MARK: - Platform Rules

        public enum IOS: String, LoadableRule {
            public var module: String {
                "@build_bazel_rules_apple//apple:ios.bzl"
            }

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

        public enum MacOS: String, LoadableRule {
            public var module: String {
                "@build_bazel_rules_apple//apple:macos.bzl"
            }

            case macos_application
            case macos_bundle
            case macos_command_line_application
            case macos_extension

            case macos_ui_test
            case macos_unit_test
            case macos_build_test

            case macos_dylib
            case macos_kernel_extension
            case macos_quick_look_plugin
            case macos_spotlight_importer
            case macos_xpc_service
        }

        public enum TVOS: String, LoadableRule {
            public var module: String {
                "@build_bazel_rules_apple//apple:tvos.bzl"
            }

            case tvos_application
            case tvos_extension
            case tvos_static_framework
            case tvos_dynamic_framework
            case tvos_ui_test
            case tvos_unit_test
            case tvos_build_test
        }

        public enum WatchOS: String, LoadableRule {
            public var module: String {
                "@build_bazel_rules_apple//apple:watchos.bzl"
            }

            case watchos_application
            case watchos_extension
            case watchos_static_framework
            case watchos_dynamic_framework
            case watchos_ui_test
            case watchos_unit_test
            case watchos_build_test
        }

        // MARK: - Shared Apple Rules

        public enum General: String, LoadableRule {
            public var module: String {
                "@build_bazel_rules_apple//apple:apple.bzl"
            }

            case apple_dynamic_framework_import
            case apple_dynamic_xcframework_import
            case apple_static_framework_import
            case apple_static_library
            case apple_static_xcframework
            case apple_static_xcframework_import
            case apple_universal_binary
            case apple_xcframework
            case local_provisioning_profile
            case provisioning_profile_repository
            case provisioning_profile_repository_extension
        }

        public enum Resources: String, LoadableRule {
            public var module: String {
                "@build_bazel_rules_apple//apple:resources.bzl"
            }

            case apple_bundle_import
            case apple_core_data_model
            case apple_core_ml_library
            case apple_resource_bundle
            case apple_resource_group
            case swift_apple_core_ml_library
            case swift_intent_library
        }

        public enum Versioning: String, LoadableRule {
            public var module: String {
                "@build_bazel_rules_apple//apple:versioning.bzl"
            }

            case apple_bundle_version
        }

        public enum Packaging: String, LoadableRule {
            public var module: String {
                "@build_bazel_rules_apple//apple:packaging.bzl"
            }

            case xcarchive
            case xctrunner
        }
    }
}

@available(*, deprecated, renamed: "Rules.Apple")
public typealias RulesApple = Rules.Apple

// MARK: - Rules.Apple.IOS.Call

extension Rules.Apple.IOS {
    public enum Call {
        /// Builds an `ios_application` target.
        public static func ios_application(
            name: String,
            bundle_id: String? = nil,
            bundle_name: String? = nil,
            deps: Starlark.Value? = nil,
            families: [String]? = nil,
            infoplists: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            resources: Starlark.Value? = nil,
            sdk_frameworks: [String]? = nil,
            strings: Starlark.Value? = nil,
            testonly: Bool? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil,
            watch_application: Starlark.Label? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.IOS.ios_application.call {
                "name" => name
                if let bundle_id { "bundle_id" => bundle_id }
                if let bundle_name { "bundle_name" => bundle_name }
                if let deps { "deps" => deps }
                if let families { "families" => families }
                if let infoplists { "infoplists" => infoplists }
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                if let resources { "resources" => resources }
                if let sdk_frameworks { "sdk_frameworks" => sdk_frameworks }
                if let strings { "strings" => strings }
                if let testonly { "testonly" => testonly }
                if let visibility { visibility }
                if let watch_application { "watch_application" => watch_application }
            }
        }

        /// Builds an `ios_framework` target.
        public static func ios_framework(
            name: String,
            bundle_id: String? = nil,
            bundle_name: String? = nil,
            deps: Starlark.Value? = nil,
            families: [String]? = nil,
            hdrs: Starlark.Value? = nil,
            infoplists: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            resources: Starlark.Value? = nil,
            strings: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.IOS.ios_framework.call {
                "name" => name
                if let bundle_id { "bundle_id" => bundle_id }
                if let bundle_name { "bundle_name" => bundle_name }
                if let deps { "deps" => deps }
                if let families { "families" => families }
                if let hdrs { "hdrs" => hdrs }
                if let infoplists { "infoplists" => infoplists }
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                if let resources { "resources" => resources }
                if let strings { "strings" => strings }
                if let visibility { visibility }
            }
        }

        public static func ios_static_framework(
            name: String,
            bundle_id: String? = nil,
            bundle_name: String? = nil,
            deps: Starlark.Value? = nil,
            families: [String]? = nil,
            hdrs: Starlark.Value? = nil,
            infoplists: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            resources: Starlark.Value? = nil,
            strings: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.IOS.ios_static_framework.call {
                "name" => name
                if let bundle_id { "bundle_id" => bundle_id }
                if let bundle_name { "bundle_name" => bundle_name }
                if let deps { "deps" => deps }
                if let families { "families" => families }
                if let hdrs { "hdrs" => hdrs }
                if let infoplists { "infoplists" => infoplists }
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                if let resources { "resources" => resources }
                if let strings { "strings" => strings }
                if let visibility { visibility }
            }
        }

        public static func ios_dynamic_framework(
            name: String,
            bundle_id: String? = nil,
            bundle_name: String? = nil,
            deps: Starlark.Value? = nil,
            families: [String]? = nil,
            hdrs: Starlark.Value? = nil,
            infoplists: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            resources: Starlark.Value? = nil,
            strings: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.IOS.ios_dynamic_framework.call {
                "name" => name
                if let bundle_id { "bundle_id" => bundle_id }
                if let bundle_name { "bundle_name" => bundle_name }
                if let deps { "deps" => deps }
                if let families { "families" => families }
                if let hdrs { "hdrs" => hdrs }
                if let infoplists { "infoplists" => infoplists }
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                if let resources { "resources" => resources }
                if let strings { "strings" => strings }
                if let visibility { visibility }
            }
        }

        public static func ios_extension(
            name: String,
            bundle_id: String? = nil,
            bundle_name: String? = nil,
            deps: Starlark.Value? = nil,
            families: [String]? = nil,
            infoplists: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            resources: Starlark.Value? = nil,
            strings: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.IOS.ios_extension.call {
                "name" => name
                if let bundle_id { "bundle_id" => bundle_id }
                if let bundle_name { "bundle_name" => bundle_name }
                if let deps { "deps" => deps }
                if let families { "families" => families }
                if let infoplists { "infoplists" => infoplists }
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                if let resources { "resources" => resources }
                if let strings { "strings" => strings }
                if let visibility { visibility }
            }
        }

        public static func ios_app_clip(
            name: String,
            bundle_id: String? = nil,
            bundle_name: String? = nil,
            deps: Starlark.Value? = nil,
            infoplists: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            resources: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.IOS.ios_app_clip.call {
                "name" => name
                if let bundle_id { "bundle_id" => bundle_id }
                if let bundle_name { "bundle_name" => bundle_name }
                if let deps { "deps" => deps }
                if let infoplists { "infoplists" => infoplists }
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                if let resources { "resources" => resources }
                if let visibility { visibility }
            }
        }

        /// Builds an `ios_unit_test` target.
        public static func ios_unit_test(
            name: String,
            data: Starlark.Value? = nil,
            deps: Starlark.Value? = nil,
            env: [String: String]? = nil,
            minimum_os_version: String? = nil,
            runner: Starlark.Label? = nil,
            test_filter: String? = nil,
            test_host: Starlark.Label? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.IOS.ios_unit_test.call {
                "name" => name
                if let data { "data" => data }
                if let deps { "deps" => deps }
                if let env { "env" => .init(env) ?? None }
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                if let runner { "runner" => runner }
                if let test_filter { "test_filter" => test_filter }
                if let test_host { "test_host" => test_host }
                if let visibility { visibility }
            }
        }

        /// Builds an `ios_ui_test` target.
        public static func ios_ui_test(
            name: String,
            data: Starlark.Value? = nil,
            deps: Starlark.Value? = nil,
            env: [String: String]? = nil,
            minimum_os_version: String? = nil,
            runner: Starlark.Label? = nil,
            test_filter: String? = nil,
            test_host: Starlark.Label? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.IOS.ios_ui_test.call {
                "name" => name
                if let data { "data" => data }
                if let deps { "deps" => deps }
                if let env { "env" => .init(env) ?? None }
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                if let runner { "runner" => runner }
                if let test_filter { "test_filter" => test_filter }
                if let test_host { "test_host" => test_host }
                if let visibility { visibility }
            }
        }

        public static func ios_unit_test_suite(
            name: String,
            minimum_os_version: String? = nil,
            runners: Starlark.Value? = nil,
            tags: [String]? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.IOS.ios_unit_test_suite.call {
                "name" => name
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                if let runners { "runners" => runners }
                if let tags { "tags" => tags }
                if let visibility { visibility }
            }
        }

        public static func ios_ui_test_suite(
            name: String,
            minimum_os_version: String? = nil,
            runners: Starlark.Value? = nil,
            tags: [String]? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.IOS.ios_ui_test_suite.call {
                "name" => name
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                if let runners { "runners" => runners }
                if let tags { "tags" => tags }
                if let visibility { visibility }
            }
        }

        public static func ios_build_test(
            name: String,
            minimum_os_version: String? = nil,
            targets: [Starlark.Label],
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.IOS.ios_build_test.call {
                "name" => name
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                "targets" => targets
                if let visibility { visibility }
            }
        }
    }
}

// MARK: - Rules.Apple.MacOS.Call

extension Rules.Apple.MacOS {
    public enum Call {
        /// Builds a `macos_application` target.
        public static func macos_application(
            name: String,
            bundle_id: String? = nil,
            bundle_name: String? = nil,
            deps: Starlark.Value? = nil,
            infoplists: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            resources: Starlark.Value? = nil,
            strings: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.MacOS.macos_application.call {
                "name" => name
                if let bundle_id { "bundle_id" => bundle_id }
                if let bundle_name { "bundle_name" => bundle_name }
                if let deps { "deps" => deps }
                if let infoplists { "infoplists" => infoplists }
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                if let resources { "resources" => resources }
                if let strings { "strings" => strings }
                if let visibility { visibility }
            }
        }

        public static func macos_extension(
            name: String,
            bundle_id: String? = nil,
            bundle_name: String? = nil,
            deps: Starlark.Value? = nil,
            infoplists: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            resources: Starlark.Value? = nil,
            strings: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.MacOS.macos_extension.call {
                "name" => name
                if let bundle_id { "bundle_id" => bundle_id }
                if let bundle_name { "bundle_name" => bundle_name }
                if let deps { "deps" => deps }
                if let infoplists { "infoplists" => infoplists }
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                if let resources { "resources" => resources }
                if let strings { "strings" => strings }
                if let visibility { visibility }
            }
        }

        /// Builds a `macos_command_line_application` target.
        public static func macos_command_line_application(
            name: String,
            bundle_id: String? = nil,
            deps: Starlark.Value? = nil,
            infoplists: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.MacOS.macos_command_line_application.call {
                "name" => name
                if let bundle_id { "bundle_id" => bundle_id }
                if let deps { "deps" => deps }
                if let infoplists { "infoplists" => infoplists }
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                if let visibility { visibility }
            }
        }

        /// Builds a `macos_unit_test` target.
        public static func macos_unit_test(
            name: String,
            data: Starlark.Value? = nil,
            deps: Starlark.Value? = nil,
            env: [String: String]? = nil,
            minimum_os_version: String? = nil,
            runner: Starlark.Label? = nil,
            test_filter: String? = nil,
            test_host: Starlark.Label? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.MacOS.macos_unit_test.call {
                "name" => name
                if let data { "data" => data }
                if let deps { "deps" => deps }
                if let env { "env" => .init(env) ?? None }
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                if let runner { "runner" => runner }
                if let test_filter { "test_filter" => test_filter }
                if let test_host { "test_host" => test_host }
                if let visibility { visibility }
            }
        }

        /// Builds a `macos_ui_test` target.
        public static func macos_ui_test(
            name: String,
            data: Starlark.Value? = nil,
            deps: Starlark.Value? = nil,
            env: [String: String]? = nil,
            minimum_os_version: String? = nil,
            runner: Starlark.Label? = nil,
            test_filter: String? = nil,
            test_host: Starlark.Label? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.MacOS.macos_ui_test.call {
                "name" => name
                if let data { "data" => data }
                if let deps { "deps" => deps }
                if let env { "env" => .init(env) ?? None }
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                if let runner { "runner" => runner }
                if let test_filter { "test_filter" => test_filter }
                if let test_host { "test_host" => test_host }
                if let visibility { visibility }
            }
        }

        public static func macos_build_test(
            name: String,
            minimum_os_version: String? = nil,
            targets: [Starlark.Label],
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.MacOS.macos_build_test.call {
                "name" => name
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                "targets" => targets
                if let visibility { visibility }
            }
        }
    }
}

// MARK: - Rules.Apple.TVOS.Call

extension Rules.Apple.TVOS {
    public enum Call {
        /// Builds a `tvos_application` target.
        public static func tvos_application(
            name: String,
            bundle_id: String? = nil,
            bundle_name: String? = nil,
            deps: Starlark.Value? = nil,
            infoplists: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            resources: Starlark.Value? = nil,
            strings: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.TVOS.tvos_application.call {
                "name" => name
                if let bundle_id { "bundle_id" => bundle_id }
                if let bundle_name { "bundle_name" => bundle_name }
                if let deps { "deps" => deps }
                if let infoplists { "infoplists" => infoplists }
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                if let resources { "resources" => resources }
                if let strings { "strings" => strings }
                if let visibility { visibility }
            }
        }

        public static func tvos_extension(
            name: String,
            bundle_id: String? = nil,
            bundle_name: String? = nil,
            deps: Starlark.Value? = nil,
            infoplists: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            resources: Starlark.Value? = nil,
            strings: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.TVOS.tvos_extension.call {
                "name" => name
                if let bundle_id { "bundle_id" => bundle_id }
                if let bundle_name { "bundle_name" => bundle_name }
                if let deps { "deps" => deps }
                if let infoplists { "infoplists" => infoplists }
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                if let resources { "resources" => resources }
                if let strings { "strings" => strings }
                if let visibility { visibility }
            }
        }

        public static func tvos_static_framework(
            name: String,
            bundle_id: String? = nil,
            bundle_name: String? = nil,
            deps: Starlark.Value? = nil,
            infoplists: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            resources: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.TVOS.tvos_static_framework.call {
                "name" => name
                if let bundle_id { "bundle_id" => bundle_id }
                if let bundle_name { "bundle_name" => bundle_name }
                if let deps { "deps" => deps }
                if let infoplists { "infoplists" => infoplists }
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                if let resources { "resources" => resources }
                if let visibility { visibility }
            }
        }

        public static func tvos_dynamic_framework(
            name: String,
            bundle_id: String? = nil,
            bundle_name: String? = nil,
            deps: Starlark.Value? = nil,
            infoplists: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            resources: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.TVOS.tvos_dynamic_framework.call {
                "name" => name
                if let bundle_id { "bundle_id" => bundle_id }
                if let bundle_name { "bundle_name" => bundle_name }
                if let deps { "deps" => deps }
                if let infoplists { "infoplists" => infoplists }
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                if let resources { "resources" => resources }
                if let visibility { visibility }
            }
        }

        /// Builds a `tvos_unit_test` target.
        public static func tvos_unit_test(
            name: String,
            data: Starlark.Value? = nil,
            deps: Starlark.Value? = nil,
            env: [String: String]? = nil,
            minimum_os_version: String? = nil,
            runner: Starlark.Label? = nil,
            test_filter: String? = nil,
            test_host: Starlark.Label? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.TVOS.tvos_unit_test.call {
                "name" => name
                if let data { "data" => data }
                if let deps { "deps" => deps }
                if let env { "env" => .init(env) ?? None }
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                if let runner { "runner" => runner }
                if let test_filter { "test_filter" => test_filter }
                if let test_host { "test_host" => test_host }
                if let visibility { visibility }
            }
        }

        /// Builds a `tvos_ui_test` target.
        public static func tvos_ui_test(
            name: String,
            data: Starlark.Value? = nil,
            deps: Starlark.Value? = nil,
            env: [String: String]? = nil,
            minimum_os_version: String? = nil,
            runner: Starlark.Label? = nil,
            test_filter: String? = nil,
            test_host: Starlark.Label? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.TVOS.tvos_ui_test.call {
                "name" => name
                if let data { "data" => data }
                if let deps { "deps" => deps }
                if let env { "env" => .init(env) ?? None }
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                if let runner { "runner" => runner }
                if let test_filter { "test_filter" => test_filter }
                if let test_host { "test_host" => test_host }
                if let visibility { visibility }
            }
        }

        public static func tvos_build_test(
            name: String,
            minimum_os_version: String? = nil,
            targets: [Starlark.Label],
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.TVOS.tvos_build_test.call {
                "name" => name
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                "targets" => targets
                if let visibility { visibility }
            }
        }
    }
}

// MARK: - Rules.Apple.WatchOS.Call

extension Rules.Apple.WatchOS {
    public enum Call {
        /// Builds a `watchos_application` target.
        public static func watchos_application(
            name: String,
            bundle_id: String? = nil,
            bundle_name: String? = nil,
            deps: Starlark.Value? = nil,
            infoplists: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            resources: Starlark.Value? = nil,
            strings: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.WatchOS.watchos_application.call {
                "name" => name
                if let bundle_id { "bundle_id" => bundle_id }
                if let bundle_name { "bundle_name" => bundle_name }
                if let deps { "deps" => deps }
                if let infoplists { "infoplists" => infoplists }
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                if let resources { "resources" => resources }
                if let strings { "strings" => strings }
                if let visibility { visibility }
            }
        }

        public static func watchos_extension(
            name: String,
            bundle_id: String? = nil,
            bundle_name: String? = nil,
            deps: Starlark.Value? = nil,
            infoplists: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            resources: Starlark.Value? = nil,
            strings: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.WatchOS.watchos_extension.call {
                "name" => name
                if let bundle_id { "bundle_id" => bundle_id }
                if let bundle_name { "bundle_name" => bundle_name }
                if let deps { "deps" => deps }
                if let infoplists { "infoplists" => infoplists }
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                if let resources { "resources" => resources }
                if let strings { "strings" => strings }
                if let visibility { visibility }
            }
        }

        public static func watchos_static_framework(
            name: String,
            bundle_id: String? = nil,
            bundle_name: String? = nil,
            deps: Starlark.Value? = nil,
            infoplists: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            resources: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.WatchOS.watchos_static_framework.call {
                "name" => name
                if let bundle_id { "bundle_id" => bundle_id }
                if let bundle_name { "bundle_name" => bundle_name }
                if let deps { "deps" => deps }
                if let infoplists { "infoplists" => infoplists }
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                if let resources { "resources" => resources }
                if let visibility { visibility }
            }
        }

        public static func watchos_dynamic_framework(
            name: String,
            bundle_id: String? = nil,
            bundle_name: String? = nil,
            deps: Starlark.Value? = nil,
            infoplists: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            resources: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.WatchOS.watchos_dynamic_framework.call {
                "name" => name
                if let bundle_id { "bundle_id" => bundle_id }
                if let bundle_name { "bundle_name" => bundle_name }
                if let deps { "deps" => deps }
                if let infoplists { "infoplists" => infoplists }
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                if let resources { "resources" => resources }
                if let visibility { visibility }
            }
        }

        /// Builds a `watchos_unit_test` target.
        public static func watchos_unit_test(
            name: String,
            data: Starlark.Value? = nil,
            deps: Starlark.Value? = nil,
            env: [String: String]? = nil,
            minimum_os_version: String? = nil,
            runner: Starlark.Label? = nil,
            test_filter: String? = nil,
            test_host: Starlark.Label? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.WatchOS.watchos_unit_test.call {
                "name" => name
                if let data { "data" => data }
                if let deps { "deps" => deps }
                if let env { "env" => .init(env) ?? None }
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                if let runner { "runner" => runner }
                if let test_filter { "test_filter" => test_filter }
                if let test_host { "test_host" => test_host }
                if let visibility { visibility }
            }
        }

        /// Builds a `watchos_ui_test` target.
        public static func watchos_ui_test(
            name: String,
            data: Starlark.Value? = nil,
            deps: Starlark.Value? = nil,
            env: [String: String]? = nil,
            minimum_os_version: String? = nil,
            runner: Starlark.Label? = nil,
            test_filter: String? = nil,
            test_host: Starlark.Label? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.WatchOS.watchos_ui_test.call {
                "name" => name
                if let data { "data" => data }
                if let deps { "deps" => deps }
                if let env { "env" => .init(env) ?? None }
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                if let runner { "runner" => runner }
                if let test_filter { "test_filter" => test_filter }
                if let test_host { "test_host" => test_host }
                if let visibility { visibility }
            }
        }

        public static func watchos_build_test(
            name: String,
            minimum_os_version: String? = nil,
            targets: [Starlark.Label],
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.WatchOS.watchos_build_test.call {
                "name" => name
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                "targets" => targets
                if let visibility { visibility }
            }
        }
    }
}

// MARK: - Rules.Apple.General.Call

extension Rules.Apple.General {
    public enum Call {
        /// Builds an `apple_dynamic_framework_import` target.
        public static func apple_dynamic_framework_import(
            name: String,
            framework_imports: Starlark.Value,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.General.apple_dynamic_framework_import.call {
                "name" => name
                "framework_imports" => framework_imports
                if let visibility { visibility }
            }
        }

        /// Builds an `apple_static_framework_import` target.
        public static func apple_static_framework_import(
            name: String,
            framework_imports: Starlark.Value,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.General.apple_static_framework_import.call {
                "name" => name
                "framework_imports" => framework_imports
                if let visibility { visibility }
            }
        }

        /// Builds an `apple_dynamic_xcframework_import` target.
        public static func apple_dynamic_xcframework_import(
            name: String,
            xcframework_imports: Starlark.Value,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.General.apple_dynamic_xcframework_import.call {
                "name" => name
                "xcframework_imports" => xcframework_imports
                if let visibility { visibility }
            }
        }

        /// Builds an `apple_static_xcframework_import` target.
        public static func apple_static_xcframework_import(
            name: String,
            xcframework_imports: Starlark.Value,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.General.apple_static_xcframework_import.call {
                "name" => name
                "xcframework_imports" => xcframework_imports
                if let visibility { visibility }
            }
        }

        /// Builds an `apple_static_library` target.
        public static func apple_static_library(
            name: String,
            deps: [Starlark.Label],
            avoid_deps: Starlark.Value? = nil,
            data: Starlark.Value? = nil,
            linkopts: [String]? = nil,
            minimum_os_version: String? = nil,
            platform_type: String? = nil,
            sdk_dylibs: [String]? = nil,
            sdk_frameworks: [String]? = nil,
            testonly: Bool? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil,
            weak_sdk_frameworks: [String]? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.General.apple_static_library.call {
                "name" => name
                "deps" => deps
                if let avoid_deps { "avoid_deps" => avoid_deps }
                if let data { "data" => data }
                if let linkopts { "linkopts" => linkopts }
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                if let platform_type { "platform_type" => platform_type }
                if let sdk_dylibs { "sdk_dylibs" => sdk_dylibs }
                if let sdk_frameworks { "sdk_frameworks" => sdk_frameworks }
                if let testonly { "testonly" => testonly }
                if let visibility { visibility }
                if let weak_sdk_frameworks { "weak_sdk_frameworks" => weak_sdk_frameworks }
            }
        }

        /// Builds an `apple_universal_binary` target.
        public static func apple_universal_binary(
            name: String,
            binary: Starlark.Label,
            minimum_os_version: String? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.General.apple_universal_binary.call {
                "name" => name
                "binary" => binary
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                if let visibility { visibility }
            }
        }

        /// Builds an `apple_xcframework` target.
        public static func apple_xcframework(
            name: String,
            bundle_name: String? = nil,
            deps: Starlark.Value? = nil,
            infoplists: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.General.apple_xcframework.call {
                "name" => name
                if let bundle_name { "bundle_name" => bundle_name }
                if let deps { "deps" => deps }
                if let infoplists { "infoplists" => infoplists }
                if let minimum_os_version { "minimum_os_version" => minimum_os_version }
                if let visibility { visibility }
            }
        }
    }
}

// MARK: - Rules.Apple.Resources.Call

extension Rules.Apple.Resources {
    public enum Call {
        /// Builds an `apple_bundle_import` target.
        public static func apple_bundle_import(
            name: String,
            bundle_imports: [Starlark.Label],
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.Resources.apple_bundle_import.call {
                "name" => name
                "bundle_imports" => bundle_imports
                if let visibility { visibility }
            }
        }

        /// Builds an `apple_core_data_model` target.
        public static func apple_core_data_model(
            name: String,
            srcs: [Starlark.Label],
            minimum_deployment_os_version: String? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.Resources.apple_core_data_model.call {
                "name" => name
                "srcs" => srcs
                if let minimum_deployment_os_version { "minimum_deployment_os_version" => minimum_deployment_os_version }
                if let visibility { visibility }
            }
        }

        /// Builds an `apple_core_ml_library` target.
        public static func apple_core_ml_library(
            name: String,
            srcs: [Starlark.Label],
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.Resources.apple_core_ml_library.call {
                "name" => name
                "srcs" => srcs
                if let visibility { visibility }
            }
        }

        /// Builds an `apple_resource_bundle` target.
        public static func apple_resource_bundle(
            name: String,
            resources: Starlark.Value? = nil,
            structured_resources: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.Resources.apple_resource_bundle.call {
                "name" => name
                if let resources { "resources" => resources }
                if let structured_resources { "structured_resources" => structured_resources }
                if let visibility { visibility }
            }
        }

        /// Builds an `apple_resource_group` target.
        public static func apple_resource_group(
            name: String,
            resources: Starlark.Value? = nil,
            structured_resources: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.Resources.apple_resource_group.call {
                "name" => name
                if let resources { "resources" => resources }
                if let structured_resources { "structured_resources" => structured_resources }
                if let visibility { visibility }
            }
        }

        /// Builds a `swift_apple_core_ml_library` target.
        public static func swift_apple_core_ml_library(
            name: String,
            srcs: [Starlark.Label],
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.Resources.swift_apple_core_ml_library.call {
                "name" => name
                "srcs" => srcs
                if let visibility { visibility }
            }
        }
    }
}

// MARK: - Rules.Apple.Versioning.Call

extension Rules.Apple.Versioning {
    public enum Call {
        /// Builds an `apple_bundle_version` target.
        public static func apple_bundle_version(
            name: String,
            build_version: String? = nil,
            short_version_string: String? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.Versioning.apple_bundle_version.call {
                "name" => name
                if let build_version { "build_version" => build_version }
                if let short_version_string { "short_version_string" => short_version_string }
                if let visibility { visibility }
            }
        }
    }
}

// MARK: - Rules.Apple.Packaging.Call

extension Rules.Apple.Packaging {
    public enum Call {
        /// Builds an `xcarchive` target.
        public static func xcarchive(
            name: String,
            bundle_name: String? = nil,
            infoplists: Starlark.Value? = nil,
            provisioning_profile: Starlark.Label? = nil,
            target: Starlark.Label,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.Packaging.xcarchive.call {
                "name" => name
                if let bundle_name { "bundle_name" => bundle_name }
                if let infoplists { "infoplists" => infoplists }
                if let provisioning_profile { "provisioning_profile" => provisioning_profile }
                "target" => target
                if let visibility { visibility }
            }
        }

        /// Builds an `xctrunner` target.
        public static func xctrunner(
            name: String,
            device_type: String? = nil,
            os_version: String? = nil,
            test_bundle: Starlark.Label,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.Packaging.xctrunner.call {
                "name" => name
                if let device_type { "device_type" => device_type }
                if let os_version { "os_version" => os_version }
                "test_bundle" => test_bundle
                if let visibility { visibility }
            }
        }
    }
}
