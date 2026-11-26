//
//  Rules+Swift.swift
//
//
//  Created by Yume on 2022/7/1.
//

import Foundation
import Starlark

// MARK: - Rules.Swift

/// https://github.com/bazelbuild/rules_swift
extension Rules {
    public enum Swift: String, LoadableRule {
        // MARK: - Swift Rules

        case swift_library
        /// `swift_binary(name, copts, deps, linkopts, module_name, srcs, stamp, swiftc_inputs)`.
        case swift_binary
        /// `swift_test(name, args, copts, data, deps, env, linkopts, module_name, srcs, stamp, swiftc_inputs)`.
        case swift_test

        // MARK: - Interop / Import

        /// `swift_import(name, archives, deps, generated_header, module_name, sdk_dylibs, sdk_frameworks, swiftinterface, swiftdoc)`.
        case swift_import
        /// `swift_c_module(name, deps, hdrs, module_map, srcs)`.
        case swift_c_module
        /// `swift_overlay(name, deps, module_name, overlay_deps, srcs)`.
        case swift_overlay
        /// `swift_interop_hint(name, exclude_hdrs, module_map, module_name, suppressed)`.
        case swift_interop_hint
        /// `swift_library_group(name, deps, exports)`.
        case swift_library_group

        // MARK: - Tooling / Generation

        /// `swift_compiler_plugin(name, deps)`.
        case swift_compiler_plugin
        /// `universal_swift_compiler_plugin(name, plugin, toolchain_types)`.
        case universal_swift_compiler_plugin
        /// `mixed_language_library(name, module_name, clang_srcs, swift_srcs, deps, data)`.
        case mixed_language_library
        /// `swift_feature_allowlist(name, package_groups)`.
        case swift_feature_allowlist
        /// `swift_grpc_library(name, deps, srcs, visibility)`.
        case swift_grpc_library
        /// `swift_proto_library(name, deps, visibility)`.
        case swift_proto_library

        public var module: String {
            switch self {
            case .swift_library:
                "@build_bazel_rules_swift//swift:swift_library.bzl"
            case .swift_binary:
                "@build_bazel_rules_swift//swift:swift_binary.bzl"
            case .swift_test:
                "@build_bazel_rules_swift//swift:swift_test.bzl"
            case .swift_import:
                "@build_bazel_rules_swift//swift:swift_import.bzl"
            case .swift_c_module:
                "@build_bazel_rules_swift//swift:swift_c_module.bzl"
            case .swift_overlay:
                "@build_bazel_rules_swift//swift:swift_overlay.bzl"
            case .swift_interop_hint:
                "@build_bazel_rules_swift//swift:swift_interop_hint.bzl"
            case .swift_library_group:
                "@build_bazel_rules_swift//swift:swift_library_group.bzl"
            case .swift_compiler_plugin, .universal_swift_compiler_plugin:
                "@build_bazel_rules_swift//swift:swift_compiler_plugin.bzl"
            case .mixed_language_library:
                "@build_bazel_rules_swift//mixed_language:mixed_language_library.bzl"
            case .swift_feature_allowlist:
                "@build_bazel_rules_swift//swift:swift_feature_allowlist.bzl"
            case .swift_grpc_library:
                "@build_bazel_rules_swift//proto:swift_grpc_library.bzl"
            case .swift_proto_library:
                "@build_bazel_rules_swift//proto:swift_proto_library.bzl"
            }
        }
    }
}

@available(*, deprecated, renamed: "Rules.Swift")
public typealias RulesSwift = Rules.Swift

// MARK: - Rules.Swift.Call

extension Rules.Swift {
    public enum Call {
        /// Builds a `swift_library` target.
        ///
        /// Reference: [rules_swift `swift_library`](https://github.com/bazelbuild/rules_swift/blob/main/doc/rules.md#swift_library)
        ///
        /// Signature:
        /// `swift_library(name, alwayslink, copts, data, defines, deps, generated_header_name, generates_header, linkopts, linkstatic, module_name, private_deps, srcs, swiftc_inputs)`.
        ///
        /// Parameters:
        /// - `name: String`
        ///   The Bazel target name.
        /// - `alwayslink: Bool`
        ///   Forces the library to be linked even when the linker would otherwise discard it. Defaults to `true`.
        /// - `copts: Starlark.Value?`
        ///   C or Clang compilation flags forwarded through the target graph.
        /// - `module_name: String?`
        ///   Overrides the emitted Swift module name.
        /// - `srcs: Starlark.Value`
        ///   Required Swift source files that make up the library.
        /// - `deps: Starlark.Value?`
        ///   Regular propagated dependencies linked into the target.
        /// - `data: Starlark.Value?`
        ///   Runtime data made available to the target.
        /// - `defines: Starlark.Value?`
        ///   Swift compilation condition symbols, including `select(...)` expressions.
        /// - `generated_header_name: String?`
        ///   Customizes the generated Objective-C compatibility header name.
        /// - `generates_header: Bool?`
        ///   Enables emitting the generated Objective-C compatibility header.
        /// - `linkopts: Starlark.Value?`
        ///   Linker flags passed through when linking downstream binaries or tests.
        /// - `linkstatic: Bool?`
        ///   Prefers static rather than dynamic linkage when supported.
        /// - `private_deps: Starlark.Value?`
        ///   Implementation-only dependencies when the toolchain supports them.
        /// - `swiftc_inputs: Starlark.Value?`
        ///   Extra files consumed by `swiftc`, such as config inputs.
        /// - `testonly: Bool?`
        ///   Repo-local convenience for emitting Bazel's `testonly` attribute.
        /// - `visibility: Starlark.Statement.Argument.Visibility?`
        ///   Repo-local convenience for emitting a `visibility` attribute.
        public static func swift_library(
            name: String,
            alwayslink: Bool = true,
            always_include_developer_search_paths: Bool? = nil,
            copts: Starlark.Value? = nil,
            module_name: String? = nil,
            package_name: String? = nil,
            plugins: Starlark.Value? = nil,
            srcs: Starlark.Value,
            deps: Starlark.Value? = nil,
            data: Starlark.Value? = nil,
            defines: Starlark.Value? = nil,
            generated_header_name: String? = nil,
            generates_header: Bool? = nil,
            linkopts: Starlark.Value? = nil,
            linkstatic: Bool? = nil,
            private_deps: Starlark.Value? = nil,
            swiftc_inputs: Starlark.Value? = nil,
            tags: [String]? = nil,
            testonly: Bool? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Swift.swift_library.call {
                Attr.name(name)
                Attr.alwayslink(alwayslink)
                Attr.always_include_developer_search_paths(always_include_developer_search_paths)
                Attr.copts(copts)
                Attr.module_name(module_name)
                Attr.package_name(package_name)
                Attr.plugins(plugins)
                Attr.srcs(srcs)
                Attr.deps(deps)
                Attr.data(data)
                Attr.defines(defines)
                Attr.generated_header_name(generated_header_name)
                Attr.generates_header(generates_header)
                Attr.linkopts(linkopts)
                Attr.linkstatic(linkstatic)
                Attr.private_deps(private_deps)
                Attr.swiftc_inputs(swiftc_inputs)
                Attr.tags(tags)
                Attr.testonly(testonly)
                Attr.visibility(visibility)
            }
        }

        /// Builds a `swift_binary` target.
        ///
        /// Reference: [rules_swift `swift_binary`](https://github.com/bazelbuild/rules_swift/blob/main/doc/rules.md#swift_binary)
        ///
        /// Signature:
        /// `swift_binary(name, copts, data, deps, linkopts, module_name, srcs, stamp, swiftc_inputs)`.
        ///
        /// Parameters:
        /// - `name: String`
        ///   The Bazel target name.
        /// - `copts: Starlark.Value?`
        ///   C or Clang compilation flags forwarded through the target graph.
        /// - `data: Starlark.Value?`
        ///   Runtime data made available to the executable.
        /// - `deps: Starlark.Value?`
        ///   Dependencies linked into the executable.
        /// - `linkopts: Starlark.Value?`
        ///   Linker flags passed when linking the executable.
        /// - `module_name: String?`
        ///   Overrides the emitted Swift module name.
        /// - `srcs: Starlark.Value?`
        ///   Swift source files that make up the executable.
        /// - `stamp: Int?`
        ///   Bazel stamping mode for build metadata.
        /// - `swiftc_inputs: Starlark.Value?`
        ///   Extra files consumed by `swiftc`, such as config inputs.
        /// - `testonly: Bool?`
        ///   Repo-local convenience for emitting Bazel's `testonly` attribute.
        /// - `visibility: Starlark.Statement.Argument.Visibility?`
        ///   Repo-local convenience for emitting a `visibility` attribute.
        public static func swift_binary(
            name: String,
            copts: Starlark.Value? = nil,
            data: Starlark.Value? = nil,
            deps: Starlark.Value? = nil,
            linkopts: Starlark.Value? = nil,
            module_name: String? = nil,
            srcs: Starlark.Value? = nil,
            stamp: Int? = nil,
            swiftc_inputs: Starlark.Value? = nil,
            tags: [String]? = nil,
            testonly: Bool? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Swift.swift_binary.call {
                Attr.name(name)
                Attr.copts(copts)
                Attr.data(data)
                Attr.deps(deps)
                Attr.linkopts(linkopts)
                Attr.module_name(module_name)
                Attr.srcs(srcs)
                Attr.stamp(stamp)
                Attr.swiftc_inputs(swiftc_inputs)
                Attr.tags(tags)
                Attr.testonly(testonly)
                Attr.visibility(visibility)
            }
        }

        /// Builds a `swift_test` target.
        ///
        /// Reference: [rules_swift `swift_test`](https://github.com/bazelbuild/rules_swift/blob/main/doc/rules.md#swift_test)
        ///
        /// Signature:
        /// `swift_test(name, args, copts, data, deps, env, linkopts, module_name, srcs, stamp, swiftc_inputs)`.
        ///
        /// Parameters:
        /// - `name: String`
        ///   The Bazel target name.
        /// - `args: [String]?`
        ///   Command-line arguments passed when running the test.
        /// - `copts: Starlark.Value?`
        ///   C or Clang compilation flags forwarded through the target graph.
        /// - `data: Starlark.Value?`
        ///   Runtime data made available to the test.
        /// - `deps: Starlark.Value?`
        ///   Dependencies linked into the test bundle.
        /// - `env: [String: String]?`
        ///   Environment variables set when the test runs.
        /// - `linkopts: Starlark.Value?`
        ///   Linker flags passed when linking the test bundle.
        /// - `module_name: String?`
        ///   Overrides the emitted Swift module name.
        /// - `srcs: Starlark.Value?`
        ///   Swift source files that make up the test target.
        /// - `stamp: Int?`
        ///   Bazel stamping mode for build metadata.
        /// - `swiftc_inputs: Starlark.Value?`
        ///   Extra files consumed by `swiftc`, such as config inputs.
        /// - `visibility: Starlark.Statement.Argument.Visibility?`
        ///   Repo-local convenience for emitting a `visibility` attribute.
        public static func swift_test(
            name: String,
            args: [String]? = nil,
            copts: Starlark.Value? = nil,
            data: Starlark.Value? = nil,
            deps: Starlark.Value? = nil,
            env: [String: String]? = nil,
            linkopts: Starlark.Value? = nil,
            module_name: String? = nil,
            srcs: Starlark.Value? = nil,
            stamp: Int? = nil,
            swiftc_inputs: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Swift.swift_test.call {
                Attr.name(name)
                Attr.args(args)
                Attr.copts(copts)
                Attr.data(data)
                Attr.deps(deps)
                Attr.env(env)
                Attr.linkopts(linkopts)
                Attr.module_name(module_name)
                Attr.srcs(srcs)
                Attr.stamp(stamp)
                Attr.swiftc_inputs(swiftc_inputs)
                Attr.visibility(visibility)
            }
        }

        /// Builds a `swift_import` target.
        ///
        /// Parameters:
        /// - `name: String`
        ///   The Bazel target name.
        /// - `archives: Starlark.Value?`
        ///   Precompiled Swift module archives or library artifacts.
        /// - `deps: Starlark.Value?`
        ///   Dependencies required by the imported module.
        /// - `data: Starlark.Value?`
        ///   Runtime data made available to the imported module.
        /// - `module_name: String`
        ///   Required Swift module name exposed by the imported artifact.
        /// - `plugins: Starlark.Value?`
        ///   Compiler plugins loaded by direct dependents of this import.
        /// - `swiftdoc: Starlark.Label?`
        ///   `.swiftdoc` file exposed by the imported module.
        /// - `swiftinterface: Starlark.Label?`
        ///   `.swiftinterface` file exposed by the imported module.
        /// - `swiftmodule: Starlark.Label?`
        ///   Precompiled `.swiftmodule` file exposed by the imported module.
        /// - `visibility: Starlark.Statement.Argument.Visibility?`
        ///   Repo-local convenience for emitting a `visibility` attribute.
        public static func swift_import(
            name: String,
            archives: Starlark.Value? = nil,
            deps: Starlark.Value? = nil,
            data: Starlark.Value? = nil,
            module_name: String,
            plugins: Starlark.Value? = nil,
            swiftdoc: Starlark.Label? = nil,
            swiftinterface: Starlark.Label? = nil,
            swiftmodule: Starlark.Label? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Swift.swift_import.call {
                Attr.name(name)
                Attr.archives(archives)
                Attr.deps(deps)
                Attr.data(data)
                Attr.module_name(module_name)
                Attr.plugins(plugins)
                Attr.swiftdoc(swiftdoc)
                Attr.swiftinterface(swiftinterface)
                Attr.swiftmodule(swiftmodule)
                Attr.visibility(visibility)
            }
        }

        /// Builds a `swift_c_module` target.
        ///
        /// Parameters:
        /// - `name: String`
        ///   The Bazel target name.
        /// - `deps: Starlark.Value?`
        ///   Dependencies required by the C module.
        /// - `hdrs: [String]?`
        ///   Header files exported by the module.
        /// - `module_map: Starlark.Label?`
        ///   Explicit module map file.
        /// - `srcs: Starlark.Value?`
        ///   Source files that participate in the module.
        /// - `visibility: Starlark.Statement.Argument.Visibility?`
        ///   Repo-local convenience for emitting a `visibility` attribute.
        public static func swift_c_module(
            name: String,
            deps: Starlark.Value? = nil,
            hdrs: [String]? = nil,
            module_map: Starlark.Label? = nil,
            srcs: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Swift.swift_c_module.call {
                Attr.name(name)
                Attr.deps(deps)
                Attr.hdrs(hdrs)
                Attr.module_map(module_map)
                Attr.srcs(srcs)
                Attr.visibility(visibility)
            }
        }

        /// Builds a `swift_overlay` target.
        ///
        /// Parameters:
        /// - `name: String`
        ///   The Bazel target name.
        /// - `deps: Starlark.Value?`
        ///   Base dependencies being overlaid.
        /// - `overlay_deps: Starlark.Value?`
        ///   Additional overlay-only dependencies.
        /// - `srcs: [Starlark.Label]`
        ///   Required Swift overlay source files.
        /// - `visibility: Starlark.Statement.Argument.Visibility?`
        ///   Repo-local convenience for emitting a `visibility` attribute.
        public static func swift_overlay(
            name: String,
            deps: Starlark.Value? = nil,
            overlay_deps: Starlark.Value? = nil,
            srcs: [Starlark.Label],
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Swift.swift_overlay.call {
                Attr.name(name)
                Attr.deps(deps)
                Attr.overlay_deps(overlay_deps)
                Attr.srcs(srcs)
                Attr.visibility(visibility)
            }
        }

        /// Builds a `swift_library_group` target.
        ///
        /// Parameters:
        /// - `name: String`
        ///   The Bazel target name.
        /// - `deps: Starlark.Value?`
        ///   Swift library dependencies grouped by this target.
        /// - `exports: Starlark.Value?`
        ///   Dependencies re-exported by the group.
        /// - `visibility: Starlark.Statement.Argument.Visibility?`
        ///   Repo-local convenience for emitting a `visibility` attribute.
        /// Builds a `swift_interop_hint` target.
        ///
        /// Reference: [rules_swift `swift_interop_hint`](https://github.com/bazelbuild/rules_swift/blob/main/doc/rules.md#swift_interop_hint)
        ///
        /// Signature:
        /// `swift_interop_hint(name, exclude_hdrs, module_map, module_name, suppressed)`.
        ///
        /// Parameters:
        /// - `name: String`
        ///   The Bazel target name.
        /// - `module_map: Starlark.Label?`
        ///   A module map written by hand, used instead of a generated one.
        /// - `module_name: String?`
        ///   The module name a Swift target imports.
        /// - `exclude_hdrs: Starlark.Value?`
        ///   Headers kept out of the generated module map.
        /// - `suppressed: Bool?`
        ///   Hides the C target from Swift entirely.
        public static func swift_interop_hint(
            name: String,
            module_map: Starlark.Label? = nil,
            module_name: String? = nil,
            exclude_hdrs: Starlark.Value? = nil,
            suppressed: Bool? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Swift.swift_interop_hint.call {
                Attr.name(name)
                Attr.module_map(module_map)
                Attr.module_name(module_name)
                Attr.exclude_hdrs(exclude_hdrs)
                Attr.suppressed(suppressed)
                Attr.visibility(visibility)
            }
        }

        public static func swift_library_group(
            name: String,
            deps: Starlark.Value? = nil,
            exports: Starlark.Value? = nil,
            tags: [String]? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Swift.swift_library_group.call {
                Attr.name(name)
                Attr.deps(deps)
                Attr.exports(exports)
                Attr.tags(tags)
                Attr.visibility(visibility)
            }
        }

        /// Builds a `swift_compiler_plugin` target.
        ///
        /// Parameters:
        /// - `name: String`
        ///   The Bazel target name.
        /// - `deps: Starlark.Value?`
        ///   Dependencies needed by the compiler plugin implementation.
        /// - `visibility: Starlark.Statement.Argument.Visibility?`
        ///   Repo-local convenience for emitting a `visibility` attribute.
        public static func swift_compiler_plugin(
            name: String,
            srcs: Starlark.Value? = nil,
            copts: Starlark.Value? = nil,
            deps: Starlark.Value? = nil,
            module_name: String? = nil,
            tags: [String]? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Swift.swift_compiler_plugin.call {
                Attr.name(name)
                Attr.srcs(srcs)
                Attr.copts(copts)
                Attr.deps(deps)
                Attr.module_name(module_name)
                Attr.tags(tags)
                Attr.visibility(visibility)
            }
        }

        /// Builds a `universal_swift_compiler_plugin` target.
        ///
        /// Parameters:
        /// - `name: String`
        ///   The Bazel target name.
        /// - `plugin: Starlark.Label`
        ///   The underlying plugin target to wrap.
        /// - `toolchain_types: Starlark.Value?`
        ///   Toolchain types supported by the universal wrapper.
        /// - `visibility: Starlark.Statement.Argument.Visibility?`
        ///   Repo-local convenience for emitting a `visibility` attribute.
        public static func universal_swift_compiler_plugin(
            name: String,
            plugin: Starlark.Label,
            toolchain_types: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Swift.universal_swift_compiler_plugin.call {
                Attr.name(name)
                Attr.plugin(plugin)
                Attr.toolchain_types(toolchain_types)
                Attr.visibility(visibility)
            }
        }

        /// Builds a `mixed_language_library` target.
        ///
        /// Parameters:
        /// - `name: String`
        ///   The Bazel target name.
        /// - `additional_objc_compiler_inputs: Starlark.Value?`
        ///   Additional Objective-C compiler inputs.
        /// - `always_include_developer_search_paths: Bool?`
        ///   Whether to include developer search paths when building.
        /// - `alwayslink: Bool?`
        ///   Whether the library should always be linked.
        /// - `clang_copts: [String]?`
        ///   C or Clang compilation flags.
        /// - `clang_defines: Starlark.Value?`
        ///   Preprocessor definitions for Clang compilation.
        /// - `clang_deps: Starlark.Value?`
        ///   Additional Clang-specific dependencies.
        /// - `clang_srcs: Starlark.Value?`
        ///   C-family sources compiled by Clang.
        /// - `data: Starlark.Value?`
        ///   Runtime data made available to the target.
        /// - `enable_modules: Bool?`
        ///   Whether Clang modules are enabled for the target.
        /// - `features: [String]?`
        ///   Bazel features for the target and the targets the macro creates.
        /// - `hdrs: Starlark.Value?`
        ///   Public C-family headers published by this mixed-language target.
        /// - `includes: [String]?`
        ///   Header search paths exported by the target.
        /// - `linkopts: Starlark.Value?`
        ///   Linker options passed through to dependents.
        /// - `module_map: Starlark.Label?`
        ///   Explicit Clang module map.
        /// - `module_name: String?`
        ///   Swift module name exposed by the mixed-language target.
        /// - `non_arc_srcs: Starlark.Value?`
        ///   Objective-C sources that should compile without ARC.
        /// - `sdk_dylibs: [String]?`
        ///   SDK dylibs to link, such as `sqlite3` or `libz`.
        /// - `sdk_frameworks: [String]?`
        ///   SDK frameworks to link strongly.
        /// - `package_name: String?`
        ///   Optional package name used for module/package identity.
        /// - `private_deps: Starlark.Value?`
        ///   Dependencies that are private to the target implementation.
        /// - `swift_copts: [String]?`
        ///   Swift compiler flags.
        /// - `swift_defines: Starlark.Value?`
        ///   Swift compilation condition symbols, including `select(...)` expressions.
        /// - `swift_plugins: Starlark.Value?`
        ///   Swift compiler plugins to apply.
        /// - `swift_srcs: Starlark.Value?`
        ///   Swift sources compiled by `swiftc`.
        /// - `swiftc_inputs: Starlark.Value?`
        ///   Extra inputs that should be available to the Swift compiler.
        /// - `textual_hdrs: Starlark.Value?`
        ///   Textual headers consumed by Clang but not modularized.
        /// - `umbrella_header: Starlark.Label?`
        ///   Umbrella header used for the generated module.
        /// - `weak_sdk_frameworks: [String]?`
        ///   SDK frameworks to weakly link.
        /// - `deps: Starlark.Value?`
        ///   Regular dependencies linked into the library.
        /// - `visibility: Starlark.Statement.Argument.Visibility?`
        ///   Repo-local convenience for emitting a `visibility` attribute.
        public static func mixed_language_library(
            name: String,
            additional_objc_compiler_inputs: Starlark.Value? = nil,
            always_include_developer_search_paths: Bool? = nil,
            alwayslink: Bool? = nil,
            clang_copts: Starlark.Value? = nil,
            clang_defines: Starlark.Value? = nil,
            clang_deps: Starlark.Value? = nil,
            clang_srcs: Starlark.Value? = nil,
            data: Starlark.Value? = nil,
            enable_modules: Bool? = nil,
            features: [String]? = nil,
            hdrs: Starlark.Value? = nil,
            includes: [String]? = nil,
            linkopts: Starlark.Value? = nil,
            module_map: Starlark.Label? = nil,
            module_name: String? = nil,
            non_arc_srcs: Starlark.Value? = nil,
            package_name: String? = nil,
            private_deps: Starlark.Value? = nil,
            sdk_dylibs: [String]? = nil,
            sdk_frameworks: [String]? = nil,
            swift_copts: Starlark.Value? = nil,
            swift_defines: Starlark.Value? = nil,
            swift_plugins: Starlark.Value? = nil,
            swift_srcs: Starlark.Value? = nil,
            swiftc_inputs: Starlark.Value? = nil,
            tags: [String]? = nil,
            textual_hdrs: Starlark.Value? = nil,
            umbrella_header: Starlark.Label? = nil,
            weak_sdk_frameworks: [String]? = nil,
            deps: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Swift.mixed_language_library.call {
                Attr.name(name)
                Attr.additional_objc_compiler_inputs(additional_objc_compiler_inputs)
                Attr.always_include_developer_search_paths(always_include_developer_search_paths)
                Attr.alwayslink(alwayslink)
                Attr.clang_copts(clang_copts)
                Attr.clang_defines(clang_defines)
                Attr.clang_deps(clang_deps)
                Attr.clang_srcs(clang_srcs)
                Attr.data(data)
                Attr.enable_modules(enable_modules)
                Attr.features(features)
                Attr.hdrs(hdrs)
                Attr.includes(includes)
                Attr.linkopts(linkopts)
                Attr.module_map(module_map)
                Attr.module_name(module_name)
                Attr.non_arc_srcs(non_arc_srcs)
                Attr.package_name(package_name)
                Attr.private_deps(private_deps)
                Attr.sdk_dylibs(sdk_dylibs)
                Attr.sdk_frameworks(sdk_frameworks)
                Attr.swift_copts(swift_copts)
                Attr.swift_defines(swift_defines)
                Attr.swift_plugins(swift_plugins)
                Attr.swift_srcs(swift_srcs)
                Attr.swiftc_inputs(swiftc_inputs)
                Attr.tags(tags)
                Attr.textual_hdrs(textual_hdrs)
                Attr.umbrella_header(umbrella_header)
                Attr.weak_sdk_frameworks(weak_sdk_frameworks)
                Attr.deps(deps)
                Attr.visibility(visibility)
            }
        }

        /// Builds a `swift_feature_allowlist` target.
        ///
        /// Parameters:
        /// - `name: String`
        ///   The Bazel target name.
        /// - `package_groups: Starlark.Value?`
        ///   Package groups granted access to the feature.
        /// - `visibility: Starlark.Statement.Argument.Visibility?`
        ///   Repo-local convenience for emitting a `visibility` attribute.
        public static func swift_feature_allowlist(
            name: String,
            package_groups: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Swift.swift_feature_allowlist.call {
                Attr.name(name)
                Attr.package_groups(package_groups)
                Attr.visibility(visibility)
            }
        }

        /// Builds a `swift_grpc_library` target.
        ///
        /// Parameters:
        /// - `name: String`
        ///   The Bazel target name.
        /// - `deps: Starlark.Value?`
        ///   Dependencies required by the generated gRPC library.
        /// - `srcs: Starlark.Value?`
        ///   Source proto declarations or generated source inputs.
        /// - `visibility: Starlark.Statement.Argument.Visibility?`
        ///   Visibility for the generated target.
        public static func swift_grpc_library(
            name: String,
            deps: Starlark.Value? = nil,
            srcs: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Swift.swift_grpc_library.call {
                Attr.name(name)
                Attr.deps(deps)
                Attr.srcs(srcs)
                Attr.visibility(visibility)
            }
        }

        /// Builds a `swift_proto_library` target.
        ///
        /// Parameters:
        /// - `name: String`
        ///   The Bazel target name.
        /// - `deps: Starlark.Value?`
        ///   Dependencies required by the generated proto library.
        /// - `visibility: Starlark.Statement.Argument.Visibility?`
        ///   Visibility for the generated target.
        public static func swift_proto_library(
            name: String,
            deps: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Swift.swift_proto_library.call {
                Attr.name(name)
                Attr.deps(deps)
                Attr.visibility(visibility)
            }
        }
    }
}
