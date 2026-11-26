//
//  Rules+Apple.swift
//
//
//  Created by Yume on 2022/7/1.
//

import Foundation
import Starlark

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
            case macos_framework
            case macos_static_framework
            case macos_dynamic_framework

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

        public enum VisionOS: String, LoadableRule {
            public var module: String {
                "@build_bazel_rules_apple//apple:visionos.bzl"
            }

            case visionos_unit_test
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
            case apple_intent_library
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

// MARK: - Rules.Apple.IOS.Call

extension Rules.Apple.IOS {
    public enum Call {
        /// Builds an `ios_application` target.
        public static func ios_application(
            name: String,
            app_icons: Starlark.Value? = nil,
            primary_app_icon: Starlark.Value? = nil,
            bundle_id: String? = nil,
            bundle_name: String? = nil,
            deps: Starlark.Value? = nil,
            entitlements: Starlark.Label? = nil,
            extensions: [Starlark.Label]? = nil,
            frameworks: [Starlark.Label]? = nil,
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
                Attr.name(name)
                Attr.app_icons(app_icons)
                Attr.primary_app_icon(primary_app_icon)
                Attr.bundle_id(bundle_id)
                Attr.bundle_name(bundle_name)
                Attr.deps(deps)
                Attr.entitlements(entitlements)
                Attr.extensions(extensions)
                if let frameworks, !frameworks.isEmpty { Attr.frameworks(frameworks) }
                Attr.families(families)
                Attr.infoplists(infoplists)
                Attr.minimum_os_version(minimum_os_version)
                Attr.resources(resources)
                Attr.sdk_frameworks(sdk_frameworks)
                Attr.strings(strings)
                Attr.testonly(testonly)
                Attr.visibility(visibility)
                Attr.watch_application(watch_application)
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
                Attr.name(name)
                Attr.bundle_id(bundle_id)
                Attr.bundle_name(bundle_name)
                Attr.deps(deps)
                Attr.families(families)
                Attr.hdrs(hdrs)
                Attr.infoplists(infoplists)
                Attr.minimum_os_version(minimum_os_version)
                Attr.resources(resources)
                Attr.strings(strings)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.bundle_id(bundle_id)
                Attr.bundle_name(bundle_name)
                Attr.deps(deps)
                Attr.families(families)
                Attr.hdrs(hdrs)
                Attr.infoplists(infoplists)
                Attr.minimum_os_version(minimum_os_version)
                Attr.resources(resources)
                Attr.strings(strings)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.bundle_id(bundle_id)
                Attr.bundle_name(bundle_name)
                Attr.deps(deps)
                Attr.families(families)
                Attr.hdrs(hdrs)
                Attr.infoplists(infoplists)
                Attr.minimum_os_version(minimum_os_version)
                Attr.resources(resources)
                Attr.strings(strings)
                Attr.visibility(visibility)
            }
        }

        public static func ios_extension(
            name: String,
            bundle_id: String? = nil,
            bundle_name: String? = nil,
            deps: Starlark.Value? = nil,
            entitlements: Starlark.Label? = nil,
            families: [String]? = nil,
            infoplists: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            resources: Starlark.Value? = nil,
            strings: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.IOS.ios_extension.call {
                Attr.name(name)
                Attr.bundle_id(bundle_id)
                Attr.bundle_name(bundle_name)
                Attr.deps(deps)
                Attr.entitlements(entitlements)
                Attr.families(families)
                Attr.infoplists(infoplists)
                Attr.minimum_os_version(minimum_os_version)
                Attr.resources(resources)
                Attr.strings(strings)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.bundle_id(bundle_id)
                Attr.bundle_name(bundle_name)
                Attr.deps(deps)
                Attr.infoplists(infoplists)
                Attr.minimum_os_version(minimum_os_version)
                Attr.resources(resources)
                Attr.visibility(visibility)
            }
        }

        /// Builds an `ios_imessage_application` target.
        ///
        /// An iMessage app has no code of its own: what it ships is the
        /// extension it carries, which is why `extensions` is what it takes
        /// instead of `deps`.
        public static func ios_imessage_application(
            name: String,
            app_icons: Starlark.Value? = nil,
            bundle_id: String? = nil,
            bundle_name: String? = nil,
            entitlements: Starlark.Label? = nil,
            extensions: [Starlark.Label]? = nil,
            families: [String]? = nil,
            infoplists: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            resources: Starlark.Value? = nil,
            strings: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.IOS.ios_imessage_application.call {
                Attr.name(name)
                Attr.app_icons(app_icons)
                Attr.bundle_id(bundle_id)
                Attr.bundle_name(bundle_name)
                Attr.entitlements(entitlements)
                if let extensions, !extensions.isEmpty { Attr.extensions(extensions) }
                Attr.families(families)
                Attr.infoplists(infoplists)
                Attr.minimum_os_version(minimum_os_version)
                Attr.resources(resources)
                Attr.strings(strings)
                Attr.visibility(visibility)
            }
        }

        /// Builds an `ios_imessage_extension` target.
        public static func ios_imessage_extension(
            name: String,
            app_icons: Starlark.Value? = nil,
            bundle_id: String? = nil,
            bundle_name: String? = nil,
            deps: Starlark.Value? = nil,
            entitlements: Starlark.Label? = nil,
            families: [String]? = nil,
            infoplists: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            resources: Starlark.Value? = nil,
            strings: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.IOS.ios_imessage_extension.call {
                Attr.name(name)
                Attr.app_icons(app_icons)
                Attr.bundle_id(bundle_id)
                Attr.bundle_name(bundle_name)
                Attr.deps(deps)
                Attr.entitlements(entitlements)
                Attr.families(families)
                Attr.infoplists(infoplists)
                Attr.minimum_os_version(minimum_os_version)
                Attr.resources(resources)
                Attr.strings(strings)
                Attr.visibility(visibility)
            }
        }

        /// Builds an `ios_sticker_pack_extension` target.
        ///
        /// Stickers are art, not code: the rule takes the asset catalog that
        /// holds them and nothing to compile.
        public static func ios_sticker_pack_extension(
            name: String,
            bundle_id: String? = nil,
            bundle_name: String? = nil,
            entitlements: Starlark.Label? = nil,
            families: [String]? = nil,
            infoplists: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            sticker_assets: Starlark.Value? = nil,
            strings: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.IOS.ios_sticker_pack_extension.call {
                Attr.name(name)
                Attr.bundle_id(bundle_id)
                Attr.bundle_name(bundle_name)
                Attr.entitlements(entitlements)
                Attr.families(families)
                Attr.infoplists(infoplists)
                Attr.minimum_os_version(minimum_os_version)
                Attr.sticker_assets(sticker_assets)
                Attr.strings(strings)
                Attr.visibility(visibility)
            }
        }

        /// Builds an `ios_unit_test` target.
        public static func ios_unit_test(
            name: String,
            data: Starlark.Value? = nil,
            deps: Starlark.Value? = nil,
            env: [String: String]? = nil,
            minimum_os_version: String? = nil,
            tags: [String]? = nil,
            target_compatible_with: [String]? = nil,
            runner: Starlark.Label? = nil,
            test_filter: String? = nil,
            test_host: Starlark.Label? = nil,
            timeout: String? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.IOS.ios_unit_test.call {
                Attr.name(name)
                Attr.data(data)
                Attr.deps(deps)
                Attr.env(env)
                Attr.minimum_os_version(minimum_os_version)
                Attr.tags(tags)
                Attr.target_compatible_with(target_compatible_with?.map { Starlark.Label.named($0) })
                Attr.runner(runner)
                Attr.test_filter(test_filter)
                Attr.test_host(test_host)
                Attr.timeout(timeout)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.data(data)
                Attr.deps(deps)
                Attr.env(env)
                Attr.minimum_os_version(minimum_os_version)
                Attr.runner(runner)
                Attr.test_filter(test_filter)
                Attr.test_host(test_host)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.minimum_os_version(minimum_os_version)
                Attr.runners(runners)
                Attr.tags(tags)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.minimum_os_version(minimum_os_version)
                Attr.runners(runners)
                Attr.tags(tags)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.minimum_os_version(minimum_os_version)
                Attr.targets(targets)
                Attr.visibility(visibility)
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
            additional_contents: [String: String]? = nil,
            app_icons: Starlark.Value? = nil,
            bundle_id: String? = nil,
            bundle_name: String? = nil,
            deps: Starlark.Value? = nil,
            entitlements: Starlark.Label? = nil,
            extensions: [Starlark.Label]? = nil,
            frameworks: [Starlark.Label]? = nil,
            infoplists: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            resources: Starlark.Value? = nil,
            strings: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.MacOS.macos_application.call {
                Attr.name(name)
                if let additional_contents, !additional_contents.isEmpty { Attr.additional_contents(additional_contents) }
                Attr.app_icons(app_icons)
                Attr.bundle_id(bundle_id)
                Attr.bundle_name(bundle_name)
                Attr.deps(deps)
                Attr.entitlements(entitlements)
                if let extensions, !extensions.isEmpty { Attr.extensions(extensions) }
                if let frameworks, !frameworks.isEmpty { Attr.frameworks(frameworks) }
                Attr.infoplists(infoplists)
                Attr.minimum_os_version(minimum_os_version)
                Attr.resources(resources)
                Attr.strings(strings)
                Attr.visibility(visibility)
            }
        }

        /// Builds a `macos_framework` target.
        public static func macos_framework(
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
            Rules.Apple.MacOS.macos_framework.call {
                Attr.name(name)
                Attr.bundle_id(bundle_id)
                Attr.bundle_name(bundle_name)
                Attr.deps(deps)
                Attr.infoplists(infoplists)
                Attr.minimum_os_version(minimum_os_version)
                Attr.resources(resources)
                Attr.visibility(visibility)
            }
        }

        public static func macos_extension(
            name: String,
            additional_contents: [String: String]? = nil,
            bundle_id: String? = nil,
            bundle_name: String? = nil,
            deps: Starlark.Value? = nil,
            entitlements: Starlark.Label? = nil,
            frameworks: [Starlark.Label]? = nil,
            infoplists: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            resources: Starlark.Value? = nil,
            strings: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.MacOS.macos_extension.call {
                Attr.name(name)
                if let additional_contents, !additional_contents.isEmpty { Attr.additional_contents(additional_contents) }
                Attr.bundle_id(bundle_id)
                Attr.bundle_name(bundle_name)
                Attr.deps(deps)
                Attr.entitlements(entitlements)
                if let frameworks, !frameworks.isEmpty { Attr.frameworks(frameworks) }
                Attr.infoplists(infoplists)
                Attr.minimum_os_version(minimum_os_version)
                Attr.resources(resources)
                Attr.strings(strings)
                Attr.visibility(visibility)
            }
        }

        /// Builds a `macos_xpc_service` target.
        public static func macos_xpc_service(
            name: String,
            additional_contents: [String: String]? = nil,
            bundle_id: String? = nil,
            bundle_name: String? = nil,
            deps: Starlark.Value? = nil,
            entitlements: Starlark.Label? = nil,
            infoplists: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            resources: Starlark.Value? = nil,
            strings: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.MacOS.macos_xpc_service.call {
                Attr.name(name)
                if let additional_contents, !additional_contents.isEmpty { Attr.additional_contents(additional_contents) }
                Attr.bundle_id(bundle_id)
                Attr.bundle_name(bundle_name)
                Attr.deps(deps)
                Attr.entitlements(entitlements)
                Attr.infoplists(infoplists)
                Attr.minimum_os_version(minimum_os_version)
                Attr.resources(resources)
                Attr.strings(strings)
                Attr.visibility(visibility)
            }
        }

        /// Builds a `macos_bundle` target.
        ///
        /// The loadable bundle every other macOS plug-in shape is a special
        /// case of: what it is a plug-in for decides the extension it carries.
        public static func macos_bundle(
            name: String,
            additional_contents: [String: String]? = nil,
            app_icons: Starlark.Value? = nil,
            bundle_extension: String? = nil,
            bundle_id: String? = nil,
            bundle_name: String? = nil,
            deps: Starlark.Value? = nil,
            entitlements: Starlark.Label? = nil,
            infoplists: Starlark.Value? = nil,
            linkopts: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            resources: Starlark.Value? = nil,
            strings: Starlark.Value? = nil,
            tags: [String]? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.MacOS.macos_bundle.call {
                Attr.name(name)
                if let additional_contents, !additional_contents.isEmpty { Attr.additional_contents(additional_contents) }
                Attr.app_icons(app_icons)
                Attr.bundle_extension(bundle_extension)
                Attr.bundle_id(bundle_id)
                Attr.bundle_name(bundle_name)
                Attr.deps(deps)
                Attr.entitlements(entitlements)
                Attr.infoplists(infoplists)
                Attr.linkopts(linkopts)
                Attr.minimum_os_version(minimum_os_version)
                Attr.resources(resources)
                Attr.strings(strings)
                Attr.tags(tags)
                Attr.visibility(visibility)
            }
        }

        /// Builds a `macos_kernel_extension` target.
        public static func macos_kernel_extension(
            name: String,
            additional_contents: [String: String]? = nil,
            bundle_id: String? = nil,
            bundle_name: String? = nil,
            deps: Starlark.Value? = nil,
            entitlements: Starlark.Label? = nil,
            infoplists: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            resources: Starlark.Value? = nil,
            strings: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.MacOS.macos_kernel_extension.call {
                Attr.name(name)
                if let additional_contents, !additional_contents.isEmpty { Attr.additional_contents(additional_contents) }
                Attr.bundle_id(bundle_id)
                Attr.bundle_name(bundle_name)
                Attr.deps(deps)
                Attr.entitlements(entitlements)
                Attr.infoplists(infoplists)
                Attr.minimum_os_version(minimum_os_version)
                Attr.resources(resources)
                Attr.strings(strings)
                Attr.visibility(visibility)
            }
        }

        /// Builds a `macos_quick_look_plugin` target.
        public static func macos_quick_look_plugin(
            name: String,
            additional_contents: [String: String]? = nil,
            bundle_id: String? = nil,
            bundle_name: String? = nil,
            deps: Starlark.Value? = nil,
            entitlements: Starlark.Label? = nil,
            infoplists: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            resources: Starlark.Value? = nil,
            strings: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.MacOS.macos_quick_look_plugin.call {
                Attr.name(name)
                if let additional_contents, !additional_contents.isEmpty { Attr.additional_contents(additional_contents) }
                Attr.bundle_id(bundle_id)
                Attr.bundle_name(bundle_name)
                Attr.deps(deps)
                Attr.entitlements(entitlements)
                Attr.infoplists(infoplists)
                Attr.minimum_os_version(minimum_os_version)
                Attr.resources(resources)
                Attr.strings(strings)
                Attr.visibility(visibility)
            }
        }

        /// Builds a `macos_spotlight_importer` target.
        public static func macos_spotlight_importer(
            name: String,
            additional_contents: [String: String]? = nil,
            bundle_id: String? = nil,
            bundle_name: String? = nil,
            deps: Starlark.Value? = nil,
            entitlements: Starlark.Label? = nil,
            infoplists: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            resources: Starlark.Value? = nil,
            strings: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.MacOS.macos_spotlight_importer.call {
                Attr.name(name)
                if let additional_contents, !additional_contents.isEmpty { Attr.additional_contents(additional_contents) }
                Attr.bundle_id(bundle_id)
                Attr.bundle_name(bundle_name)
                Attr.deps(deps)
                Attr.entitlements(entitlements)
                Attr.infoplists(infoplists)
                Attr.minimum_os_version(minimum_os_version)
                Attr.resources(resources)
                Attr.strings(strings)
                Attr.visibility(visibility)
            }
        }

        /// Builds a `macos_dylib` target.
        ///
        /// A dynamic library with no bundle around it: whatever loads it says
        /// where it is, so there is nothing to place resources in.
        public static func macos_dylib(
            name: String,
            bundle_id: String? = nil,
            deps: Starlark.Value? = nil,
            infoplists: Starlark.Value? = nil,
            linkopts: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.MacOS.macos_dylib.call {
                Attr.name(name)
                Attr.bundle_id(bundle_id)
                Attr.deps(deps)
                Attr.infoplists(infoplists)
                Attr.linkopts(linkopts)
                Attr.minimum_os_version(minimum_os_version)
                Attr.visibility(visibility)
            }
        }

        /// Builds a `macos_dynamic_framework` target.
        public static func macos_dynamic_framework(
            name: String,
            bundle_id: String? = nil,
            bundle_name: String? = nil,
            deps: Starlark.Value? = nil,
            hdrs: Starlark.Value? = nil,
            infoplists: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            resources: Starlark.Value? = nil,
            strings: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.MacOS.macos_dynamic_framework.call {
                Attr.name(name)
                Attr.bundle_id(bundle_id)
                Attr.bundle_name(bundle_name)
                Attr.deps(deps)
                Attr.hdrs(hdrs)
                Attr.infoplists(infoplists)
                Attr.minimum_os_version(minimum_os_version)
                Attr.resources(resources)
                Attr.strings(strings)
                Attr.visibility(visibility)
            }
        }

        /// Builds a `macos_static_framework` target.
        ///
        /// A framework that is linked rather than loaded: the objects end up in
        /// whatever links it, which is why `avoid_deps` is how a dependency is
        /// kept out of it.
        public static func macos_static_framework(
            name: String,
            avoid_deps: Starlark.Value? = nil,
            bundle_name: String? = nil,
            deps: Starlark.Value? = nil,
            hdrs: Starlark.Value? = nil,
            minimum_os_version: String? = nil,
            resources: Starlark.Value? = nil,
            umbrella_header: Starlark.Label? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.MacOS.macos_static_framework.call {
                Attr.name(name)
                Attr.avoid_deps(avoid_deps)
                Attr.bundle_name(bundle_name)
                Attr.deps(deps)
                Attr.hdrs(hdrs)
                Attr.minimum_os_version(minimum_os_version)
                Attr.resources(resources)
                Attr.umbrella_header(umbrella_header)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.bundle_id(bundle_id)
                Attr.deps(deps)
                Attr.infoplists(infoplists)
                Attr.minimum_os_version(minimum_os_version)
                Attr.visibility(visibility)
            }
        }

        /// Builds a `macos_unit_test` target.
        public static func macos_unit_test(
            name: String,
            data: Starlark.Value? = nil,
            deps: Starlark.Value? = nil,
            env: [String: String]? = nil,
            minimum_os_version: String? = nil,
            target_compatible_with: [String]? = nil,
            runner: Starlark.Label? = nil,
            test_filter: String? = nil,
            test_host: Starlark.Label? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.MacOS.macos_unit_test.call {
                Attr.name(name)
                Attr.data(data)
                Attr.deps(deps)
                Attr.env(env)
                Attr.minimum_os_version(minimum_os_version)
                Attr.target_compatible_with(target_compatible_with?.map { Starlark.Label.named($0) })
                Attr.runner(runner)
                Attr.test_filter(test_filter)
                Attr.test_host(test_host)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.data(data)
                Attr.deps(deps)
                Attr.env(env)
                Attr.minimum_os_version(minimum_os_version)
                Attr.runner(runner)
                Attr.test_filter(test_filter)
                Attr.test_host(test_host)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.minimum_os_version(minimum_os_version)
                Attr.targets(targets)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.bundle_id(bundle_id)
                Attr.bundle_name(bundle_name)
                Attr.deps(deps)
                Attr.infoplists(infoplists)
                Attr.minimum_os_version(minimum_os_version)
                Attr.resources(resources)
                Attr.strings(strings)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.bundle_id(bundle_id)
                Attr.bundle_name(bundle_name)
                Attr.deps(deps)
                Attr.infoplists(infoplists)
                Attr.minimum_os_version(minimum_os_version)
                Attr.resources(resources)
                Attr.strings(strings)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.bundle_id(bundle_id)
                Attr.bundle_name(bundle_name)
                Attr.deps(deps)
                Attr.infoplists(infoplists)
                Attr.minimum_os_version(minimum_os_version)
                Attr.resources(resources)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.bundle_id(bundle_id)
                Attr.bundle_name(bundle_name)
                Attr.deps(deps)
                Attr.infoplists(infoplists)
                Attr.minimum_os_version(minimum_os_version)
                Attr.resources(resources)
                Attr.visibility(visibility)
            }
        }

        /// Builds a `tvos_unit_test` target.
        public static func tvos_unit_test(
            name: String,
            data: Starlark.Value? = nil,
            deps: Starlark.Value? = nil,
            env: [String: String]? = nil,
            minimum_os_version: String? = nil,
            tags: [String]? = nil,
            target_compatible_with: [String]? = nil,
            runner: Starlark.Label? = nil,
            test_filter: String? = nil,
            test_host: Starlark.Label? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.TVOS.tvos_unit_test.call {
                Attr.name(name)
                Attr.data(data)
                Attr.deps(deps)
                Attr.env(env)
                Attr.minimum_os_version(minimum_os_version)
                Attr.tags(tags)
                Attr.target_compatible_with(target_compatible_with?.map { Starlark.Label.named($0) })
                Attr.runner(runner)
                Attr.test_filter(test_filter)
                Attr.test_host(test_host)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.data(data)
                Attr.deps(deps)
                Attr.env(env)
                Attr.minimum_os_version(minimum_os_version)
                Attr.runner(runner)
                Attr.test_filter(test_filter)
                Attr.test_host(test_host)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.minimum_os_version(minimum_os_version)
                Attr.targets(targets)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.bundle_id(bundle_id)
                Attr.bundle_name(bundle_name)
                Attr.deps(deps)
                Attr.infoplists(infoplists)
                Attr.minimum_os_version(minimum_os_version)
                Attr.resources(resources)
                Attr.strings(strings)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.bundle_id(bundle_id)
                Attr.bundle_name(bundle_name)
                Attr.deps(deps)
                Attr.infoplists(infoplists)
                Attr.minimum_os_version(minimum_os_version)
                Attr.resources(resources)
                Attr.strings(strings)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.bundle_id(bundle_id)
                Attr.bundle_name(bundle_name)
                Attr.deps(deps)
                Attr.infoplists(infoplists)
                Attr.minimum_os_version(minimum_os_version)
                Attr.resources(resources)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.bundle_id(bundle_id)
                Attr.bundle_name(bundle_name)
                Attr.deps(deps)
                Attr.infoplists(infoplists)
                Attr.minimum_os_version(minimum_os_version)
                Attr.resources(resources)
                Attr.visibility(visibility)
            }
        }

        /// Builds a `watchos_unit_test` target.
        public static func watchos_unit_test(
            name: String,
            data: Starlark.Value? = nil,
            deps: Starlark.Value? = nil,
            env: [String: String]? = nil,
            minimum_os_version: String? = nil,
            tags: [String]? = nil,
            target_compatible_with: [String]? = nil,
            runner: Starlark.Label? = nil,
            test_filter: String? = nil,
            test_host: Starlark.Label? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.WatchOS.watchos_unit_test.call {
                Attr.name(name)
                Attr.data(data)
                Attr.deps(deps)
                Attr.env(env)
                Attr.minimum_os_version(minimum_os_version)
                Attr.tags(tags)
                Attr.target_compatible_with(target_compatible_with?.map { Starlark.Label.named($0) })
                Attr.runner(runner)
                Attr.test_filter(test_filter)
                Attr.test_host(test_host)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.data(data)
                Attr.deps(deps)
                Attr.env(env)
                Attr.minimum_os_version(minimum_os_version)
                Attr.runner(runner)
                Attr.test_filter(test_filter)
                Attr.test_host(test_host)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.minimum_os_version(minimum_os_version)
                Attr.targets(targets)
                Attr.visibility(visibility)
            }
        }
    }
}

// MARK: - Rules.Apple.VisionOS.Call

extension Rules.Apple.VisionOS {
    public enum Call {
        /// Builds a `visionos_unit_test` target.
        public static func visionos_unit_test(
            name: String,
            data: Starlark.Value? = nil,
            deps: Starlark.Value? = nil,
            env: [String: String]? = nil,
            minimum_os_version: String? = nil,
            runner: Starlark.Label? = nil,
            tags: [String]? = nil,
            target_compatible_with: [String]? = nil,
            test_filter: String? = nil,
            test_host: Starlark.Label? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.VisionOS.visionos_unit_test.call {
                Attr.name(name)
                Attr.data(data)
                Attr.deps(deps)
                Attr.env(env)
                Attr.minimum_os_version(minimum_os_version)
                Attr.runner(runner)
                Attr.tags(tags)
                Attr.target_compatible_with(target_compatible_with?.map { Starlark.Label.named($0) })
                Attr.test_filter(test_filter)
                Attr.test_host(test_host)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.framework_imports(framework_imports)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.framework_imports(framework_imports)
                Attr.visibility(visibility)
            }
        }

        /// Builds an `apple_dynamic_xcframework_import` target.
        public static func apple_dynamic_xcframework_import(
            name: String,
            xcframework_imports: Starlark.Value,
            tags: [String]? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.General.apple_dynamic_xcframework_import.call {
                Attr.name(name)
                Attr.xcframework_imports(xcframework_imports)
                Attr.tags(tags)
                Attr.visibility(visibility)
            }
        }

        /// Builds an `apple_static_xcframework_import` target.
        public static func apple_static_xcframework_import(
            name: String,
            xcframework_imports: Starlark.Value,
            tags: [String]? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.General.apple_static_xcframework_import.call {
                Attr.name(name)
                Attr.xcframework_imports(xcframework_imports)
                Attr.tags(tags)
                Attr.visibility(visibility)
            }
        }

        /// Builds an `apple_static_library` target.
        public static func apple_static_library(
            name: String,
            deps: [Starlark.Label],
            avoid_deps: Starlark.Value? = nil,
            data: Starlark.Value? = nil,
            linkopts: Starlark.Value? = nil,
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
                Attr.name(name)
                Attr.deps(deps)
                Attr.avoid_deps(avoid_deps)
                Attr.data(data)
                Attr.linkopts(linkopts)
                Attr.minimum_os_version(minimum_os_version)
                Attr.platform_type(platform_type)
                Attr.sdk_dylibs(sdk_dylibs)
                Attr.sdk_frameworks(sdk_frameworks)
                Attr.testonly(testonly)
                Attr.visibility(visibility)
                Attr.weak_sdk_frameworks(weak_sdk_frameworks)
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
                Attr.name(name)
                Attr.binary(binary)
                Attr.minimum_os_version(minimum_os_version)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.bundle_name(bundle_name)
                Attr.deps(deps)
                Attr.infoplists(infoplists)
                Attr.minimum_os_version(minimum_os_version)
                Attr.visibility(visibility)
            }
        }

        /// Builds an `apple_static_xcframework` target.
        ///
        /// The static half of `apple_xcframework`: one archive per platform,
        /// linked by whoever imports it, with the headers it publishes.
        public static func apple_static_xcframework(
            name: String,
            avoid_deps: Starlark.Value? = nil,
            bundle_name: String? = nil,
            deps: Starlark.Value? = nil,
            minimum_os_versions: [String: String]? = nil,
            public_hdrs: Starlark.Value? = nil,
            umbrella_header: Starlark.Label? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.General.apple_static_xcframework.call {
                Attr.name(name)
                Attr.avoid_deps(avoid_deps)
                Attr.bundle_name(bundle_name)
                Attr.deps(deps)
                if let minimum_os_versions, !minimum_os_versions.isEmpty { Attr.minimum_os_versions(minimum_os_versions) }
                Attr.public_hdrs(public_hdrs)
                Attr.umbrella_header(umbrella_header)
                Attr.visibility(visibility)
            }
        }

        /// Builds a `local_provisioning_profile` target.
        ///
        /// The profile a device build has to be signed with, taken from the
        /// machine that runs the build rather than from the workspace: a
        /// profile is issued to a developer, so it is never a source file.
        public static func local_provisioning_profile(
            name: String,
            profile_name: String? = nil,
            teamid: String? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.General.local_provisioning_profile.call {
                Attr.name(name)
                Attr.profile_name(profile_name)
                Attr.teamid(teamid)
                Attr.visibility(visibility)
            }
        }

        /// Builds a `provisioning_profile_repository` target.
        ///
        /// Where `local_provisioning_profile` looks: the profiles Xcode
        /// downloaded, with the ones a machine without them falls back to.
        public static func provisioning_profile_repository(
            name: String,
            fallback_profiles: Starlark.Label? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.General.provisioning_profile_repository.call {
                Attr.name(name)
                Attr.fallback_profiles(fallback_profiles)
                Attr.visibility(visibility)
            }
        }

        /// Builds a `provisioning_profile_repository_extension` call.
        ///
        /// The same repository, declared the way a `MODULE.bazel` declares one:
        /// a module extension rather than a target.
        public static func provisioning_profile_repository_extension(
            name: String,
            fallback_profiles: Starlark.Label? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.General.provisioning_profile_repository_extension.call {
                Attr.name(name)
                Attr.fallback_profiles(fallback_profiles)
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
                Attr.name(name)
                Attr.bundle_imports(bundle_imports)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.srcs(srcs)
                Attr.minimum_deployment_os_version(minimum_deployment_os_version)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.srcs(srcs)
                Attr.visibility(visibility)
            }
        }

        /// Builds an `apple_resource_bundle` target.
        public static func apple_resource_bundle(
            name: String,
            bundle_name: String? = nil,
            infoplists: Starlark.Value? = nil,
            resources: Starlark.Value? = nil,
            structured_resources: Starlark.Value? = nil,
            tags: [String]? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.Resources.apple_resource_bundle.call {
                Attr.name(name)
                Attr.bundle_name(bundle_name)
                Attr.infoplists(infoplists)
                Attr.resources(resources)
                Attr.structured_resources(structured_resources)
                Attr.tags(tags)
                Attr.visibility(visibility)
            }
        }

        /// Builds an `apple_resource_group` target.
        public static func apple_resource_group(
            name: String,
            resources: Starlark.Value? = nil,
            strip_structured_resources_prefixes: [String]? = nil,
            structured_resources: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.Resources.apple_resource_group.call {
                Attr.name(name)
                Attr.resources(resources)
                if
                    let strip_structured_resources_prefixes,
                    !strip_structured_resources_prefixes
                        .isEmpty { Attr.strip_structured_resources_prefixes(strip_structured_resources_prefixes) }
                Attr.structured_resources(structured_resources)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.srcs(srcs)
                Attr.visibility(visibility)
            }
        }

        /// Builds a `swift_intent_library` target.
        ///
        /// Parameters:
        /// - `name: String`
        ///   The Bazel target name.
        /// - `src: Starlark.Label`
        ///   The `.intentdefinition` file to generate classes from.
        /// - `class_prefix: String?`
        ///   Class prefix for the generated classes.
        /// - `class_visibility: String?`
        ///   Swift visibility of the generated classes: `public`, `private` or `project`.
        /// - `swift_version: String?`
        ///   Swift language version used for the generated classes.
        /// - `testonly: Bool?`
        ///   Repo-local convenience for emitting Bazel's `testonly` attribute.
        /// - `visibility: Starlark.Statement.Argument.Visibility?`
        ///   Repo-local convenience for emitting a `visibility` attribute.
        public static func swift_intent_library(
            name: String,
            src: Starlark.Label,
            class_prefix: String? = nil,
            class_visibility: String? = nil,
            swift_version: String? = nil,
            testonly: Bool? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.Resources.swift_intent_library.call {
                Attr.name(name)
                Attr.src(src)
                Attr.class_prefix(class_prefix)
                Attr.class_visibility(class_visibility)
                Attr.swift_version(swift_version)
                Attr.testonly(testonly)
                Attr.visibility(visibility)
            }
        }

        /// Builds an `apple_intent_library` target.
        ///
        /// Unlike `swift_intent_library` this exposes the generated sources directly,
        /// so they can be compiled into the module that uses them — which is how
        /// Xcode treats an `.intentdefinition` belonging to a target.
        ///
        /// Parameters:
        /// - `name: String`
        ///   The Bazel target name.
        /// - `src: Starlark.Label`
        ///   The `.intentdefinition` file to generate classes from.
        /// - `language: String`
        ///   `Swift` or `Objective-C`.
        /// - `class_prefix: String?`
        ///   Class prefix for the generated classes.
        /// - `class_visibility: String?`
        ///   Swift visibility of the generated classes: `public`, `private` or `project`.
        /// - `header_name: String?`
        ///   Generated header name, required for Objective-C.
        /// - `swift_version: String?`
        ///   Swift language version used for the generated classes.
        /// - `tags: [String]?`
        ///   Bazel tags; the rule is meant to be built only through its consumer.
        /// - `testonly: Bool?`
        ///   Repo-local convenience for emitting Bazel's `testonly` attribute.
        /// - `visibility: Starlark.Statement.Argument.Visibility?`
        ///   Repo-local convenience for emitting a `visibility` attribute.
        public static func apple_intent_library(
            name: String,
            src: Starlark.Label,
            language: String,
            class_prefix: String? = nil,
            class_visibility: String? = nil,
            header_name: String? = nil,
            swift_version: String? = nil,
            tags: [String]? = nil,
            testonly: Bool? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Apple.Resources.apple_intent_library.call {
                Attr.name(name)
                Attr.src(src)
                Attr.language(language)
                Attr.class_prefix(class_prefix)
                Attr.class_visibility(class_visibility)
                Attr.header_name(header_name)
                Attr.swift_version(swift_version)
                Attr.tags(tags)
                Attr.testonly(testonly)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.build_version(build_version)
                Attr.short_version_string(short_version_string)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.bundle_name(bundle_name)
                Attr.infoplists(infoplists)
                Attr.provisioning_profile(provisioning_profile)
                Attr.target(target)
                Attr.visibility(visibility)
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
                Attr.name(name)
                Attr.device_type(device_type)
                Attr.os_version(os_version)
                Attr.test_bundle(test_bundle)
                Attr.visibility(visibility)
            }
        }
    }
}
