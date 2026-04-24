//
//  Rules+Swift.swift
//
//
//  Created by Yume on 2022/7/1.
//

import Foundation
import RuleBuilder

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
        /// `swift_library_group(name, deps, exports)`.
        case swift_library_group

        // MARK: - Tooling / Generation

        /// `swift_compiler_plugin(name, deps)`.
        case swift_compiler_plugin
        /// `universal_swift_compiler_plugin(name, plugin, toolchain_types)`.
        case universal_swift_compiler_plugin
        /// `mixed_language_library(name, module_name, srcs, deps, data, defines, copts)`.
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
        /// - `copts: [String]?`
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
        /// - `linkopts: [String]?`
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
            copts: [String]? = nil,
            module_name: String? = nil,
            srcs: Starlark.Value,
            deps: Starlark.Value? = nil,
            data: Starlark.Value? = nil,
            defines: Starlark.Value? = nil,
            generated_header_name: String? = nil,
            generates_header: Bool? = nil,
            linkopts: [String]? = nil,
            linkstatic: Bool? = nil,
            private_deps: Starlark.Value? = nil,
            swiftc_inputs: Starlark.Value? = nil,
            testonly: Bool? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Swift.swift_library.call {
                "name" => name
                "alwayslink" => alwayslink
                if let copts {
                    "copts" => copts
                }
                if let module_name {
                    "module_name" => module_name
                }
                "srcs" => srcs

                if let deps {
                    "deps" => deps
                }
                if let data {
                    "data" => data
                }
                if let defines {
                    "defines" => defines
                }
                if let generated_header_name {
                    "generated_header_name" => generated_header_name
                }
                if let generates_header {
                    "generates_header" => generates_header
                }
                if let linkopts {
                    "linkopts" => linkopts
                }
                if let linkstatic {
                    "linkstatic" => linkstatic
                }
                if let private_deps {
                    "private_deps" => private_deps
                }
                if let swiftc_inputs {
                    "swiftc_inputs" => swiftc_inputs
                }
                if let testonly {
                    "testonly" => testonly
                }
                if let visibility {
                    visibility
                }
            }
        }

        /// Builds a `swift_binary` target.
        ///
        /// Reference: [rules_swift `swift_binary`](https://github.com/bazelbuild/rules_swift/blob/main/doc/rules.md#swift_binary)
        ///
        /// Signature:
        /// `swift_binary(name, copts, deps, linkopts, module_name, srcs, stamp, swiftc_inputs)`.
        ///
        /// Parameters:
        /// - `name: String`
        ///   The Bazel target name.
        /// - `copts: [String]?`
        ///   C or Clang compilation flags forwarded through the target graph.
        /// - `deps: Starlark.Value?`
        ///   Dependencies linked into the executable.
        /// - `linkopts: [String]?`
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
            copts: [String]? = nil,
            deps: Starlark.Value? = nil,
            linkopts: [String]? = nil,
            module_name: String? = nil,
            srcs: Starlark.Value? = nil,
            stamp: Int? = nil,
            swiftc_inputs: Starlark.Value? = nil,
            testonly: Bool? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Swift.swift_binary.call {
                "name" => name
                if let copts {
                    "copts" => copts
                }
                if let deps {
                    "deps" => deps
                }
                if let linkopts {
                    "linkopts" => linkopts
                }
                if let module_name {
                    "module_name" => module_name
                }
                if let srcs {
                    "srcs" => srcs
                }
                if let stamp {
                    "stamp" => .int(stamp)
                }
                if let swiftc_inputs {
                    "swiftc_inputs" => swiftc_inputs
                }
                if let testonly {
                    "testonly" => testonly
                }
                if let visibility {
                    visibility
                }
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
        /// - `copts: [String]?`
        ///   C or Clang compilation flags forwarded through the target graph.
        /// - `data: Starlark.Value?`
        ///   Runtime data made available to the test.
        /// - `deps: Starlark.Value?`
        ///   Dependencies linked into the test bundle.
        /// - `env: [String: String]?`
        ///   Environment variables set when the test runs.
        /// - `linkopts: [String]?`
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
            copts: [String]? = nil,
            data: Starlark.Value? = nil,
            deps: Starlark.Value? = nil,
            env: [String: String]? = nil,
            linkopts: [String]? = nil,
            module_name: String? = nil,
            srcs: Starlark.Value? = nil,
            stamp: Int? = nil,
            swiftc_inputs: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Swift.swift_test.call {
                "name" => name
                if let args {
                    "args" => args
                }
                if let copts {
                    "copts" => copts
                }
                if let data {
                    "data" => data
                }
                if let deps {
                    "deps" => deps
                }
                if let env {
                    "env" => .init(env) ?? None
                }
                if let linkopts {
                    "linkopts" => linkopts
                }
                if let module_name {
                    "module_name" => module_name
                }
                if let srcs {
                    "srcs" => srcs
                }
                if let stamp {
                    "stamp" => .int(stamp)
                }
                if let swiftc_inputs {
                    "swiftc_inputs" => swiftc_inputs
                }
                if let visibility {
                    visibility
                }
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
                "name" => name
                if let archives { "archives" => archives }
                if let deps { "deps" => deps }
                if let data { "data" => data }
                "module_name" => module_name
                if let plugins { "plugins" => plugins }
                if let swiftdoc { "swiftdoc" => swiftdoc }
                if let swiftinterface { "swiftinterface" => swiftinterface }
                if let swiftmodule { "swiftmodule" => swiftmodule }
                if let visibility { visibility }
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
                "name" => name
                if let deps { "deps" => deps }
                if let hdrs { "hdrs" => hdrs }
                if let module_map { "module_map" => module_map }
                if let srcs { "srcs" => srcs }
                if let visibility { visibility }
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
                "name" => name
                if let deps { "deps" => deps }
                if let overlay_deps { "overlay_deps" => overlay_deps }
                "srcs" => srcs
                if let visibility { visibility }
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
        public static func swift_library_group(
            name: String,
            deps: Starlark.Value? = nil,
            exports: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Swift.swift_library_group.call {
                "name" => name
                if let deps { "deps" => deps }
                if let exports { "exports" => exports }
                if let visibility { visibility }
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
            deps: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Swift.swift_compiler_plugin.call {
                "name" => name
                if let deps { "deps" => deps }
                if let visibility { visibility }
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
                "name" => name
                "plugin" => plugin
                if let toolchain_types { "toolchain_types" => toolchain_types }
                if let visibility { visibility }
            }
        }

        /// Builds a `mixed_language_library` target.
        ///
        /// Parameters:
        /// - `name: String`
        ///   The Bazel target name.
        /// - `module_name: String?`
        ///   Swift module name exposed by the mixed-language target.
        /// - `srcs: Starlark.Value?`
        ///   Swift and Objective-C source files in the target.
        /// - `deps: Starlark.Value?`
        ///   Regular dependencies linked into the library.
        /// - `data: Starlark.Value?`
        ///   Runtime data made available to the target.
        /// - `defines: Starlark.Value?`
        ///   Compilation condition symbols, including `select(...)` expressions.
        /// - `copts: [String]?`
        ///   C or Clang compilation flags.
        /// - `always_include_developer_search_paths: Bool?`
        ///   Whether to include developer search paths when building.
        /// - `clang_deps: Starlark.Value?`
        ///   Additional Clang-specific dependencies.
        /// - `package_name: String?`
        ///   Optional package name used for module/package identity.
        /// - `visibility: Starlark.Statement.Argument.Visibility?`
        ///   Repo-local convenience for emitting a `visibility` attribute.
        public static func mixed_language_library(
            name: String,
            module_name: String? = nil,
            srcs: Starlark.Value? = nil,
            deps: Starlark.Value? = nil,
            data: Starlark.Value? = nil,
            defines: Starlark.Value? = nil,
            copts: [String]? = nil,
            always_include_developer_search_paths: Bool? = nil,
            clang_deps: Starlark.Value? = nil,
            package_name: String? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Swift.mixed_language_library.call {
                "name" => name
                if let module_name { "module_name" => module_name }
                if let srcs { "srcs" => srcs }
                if let deps { "deps" => deps }
                if let data { "data" => data }
                if let defines { "defines" => defines }
                if let copts { "copts" => copts }
                if let always_include_developer_search_paths {
                    "always_include_developer_search_paths" => always_include_developer_search_paths
                }
                if let clang_deps { "clang_deps" => clang_deps }
                if let package_name { "package_name" => package_name }
                if let visibility { visibility }
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
                "name" => name
                if let package_groups {
                    "package_groups" => package_groups
                }
                if let visibility { visibility }
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
                "name" => name
                if let deps { "deps" => deps }
                if let srcs { "srcs" => srcs }
                if let visibility { visibility }
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
                "name" => name
                if let deps { "deps" => deps }
                if let visibility { visibility }
            }
        }
    }
}
