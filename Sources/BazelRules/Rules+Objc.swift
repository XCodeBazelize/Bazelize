//
//  Rules+Objc.swift
//
//
//  Created by Yume on 2022/7/22.
//

import Foundation
import Starlark

// MARK: - Rules.Objc

/// https://bazel.build/reference/be/objective-c
extension Rules {
    public enum Objc: String, LoadableRule {
        public var module: String {
            "@rules_cc//cc:defs.bzl"
        }

        // MARK: - Objective-C Rules

        case objc_library
        case objc_import
        case j2objc_library

        // MARK: - Xcode Configuration

        case available_xcodes
        case xcode_config
        case xcode_version
    }
}

@available(*, deprecated, renamed: "Rules.Objc")
public typealias RulesObjc = Rules.Objc

// MARK: - Rules.Objc.Call

extension Rules.Objc {
    public enum Call {
        /// Builds an `objc_library` target.
        ///
        /// Reference: [Bazel `objc_library`](https://bazel.build/reference/be/objective-c#objc_library)
        public static func objc_library(
            name: String,
            aspect_hints: Starlark.Value? = nil,
            srcs: Starlark.Value? = nil,
            hdrs: Starlark.Value? = nil,
            deps: Starlark.Value? = nil,
            data: Starlark.Value? = nil,
            alwayslink: Bool? = nil,
            copts: Starlark.Value? = nil,
            defines: [String]? = nil,
            enable_modules: Bool? = nil,
            includes: [String]? = nil,
            linkopts: Starlark.Value? = nil,
            module_map: Starlark.Label? = nil,
            module_name: String? = nil,
            non_arc_srcs: Starlark.Value? = nil,
            pch: Starlark.Label? = nil,
            sdk_dylibs: [String]? = nil,
            sdk_frameworks: [String]? = nil,
            sdk_includes: [String]? = nil,
            tags: [String]? = nil,
            textual_hdrs: Starlark.Value? = nil,
            testonly: Bool? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil,
            weak_sdk_frameworks: [String]? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Objc.objc_library.call {
                Attr.name(name)
                Attr.aspect_hints(aspect_hints)
                Attr.srcs(srcs)
                Attr.hdrs(hdrs)
                Attr.deps(deps)
                Attr.data(data)
                Attr.alwayslink(alwayslink)
                Attr.copts(copts)
                Attr.defines(defines)
                Attr.enable_modules(enable_modules)
                Attr.includes(includes)
                Attr.linkopts(linkopts)
                Attr.module_map(module_map)
                Attr.module_name(module_name)
                Attr.non_arc_srcs(non_arc_srcs)
                Attr.pch(pch)
                Attr.sdk_dylibs(sdk_dylibs)
                Attr.sdk_frameworks(sdk_frameworks)
                Attr.sdk_includes(sdk_includes)
                Attr.tags(tags)
                Attr.textual_hdrs(textual_hdrs)
                Attr.testonly(testonly)
                Attr.visibility(visibility)
                Attr.weak_sdk_frameworks(weak_sdk_frameworks)
            }
        }

        /// Builds an `objc_import` target.
        ///
        /// Reference: [Bazel `objc_import`](https://bazel.build/reference/be/objective-c#objc_import)
        public static func objc_import(
            name: String,
            archives: Starlark.Value? = nil,
            deps: Starlark.Value? = nil,
            hdrs: Starlark.Value? = nil,
            sdk_dylibs: [String]? = nil,
            sdk_frameworks: [String]? = nil,
            alwayslink: Bool? = nil,
            testonly: Bool? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil,
            weak_sdk_frameworks: [String]? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Objc.objc_import.call {
                Attr.name(name)
                Attr.archives(archives)
                Attr.deps(deps)
                Attr.hdrs(hdrs)
                Attr.sdk_dylibs(sdk_dylibs)
                Attr.sdk_frameworks(sdk_frameworks)
                Attr.alwayslink(alwayslink)
                Attr.testonly(testonly)
                Attr.visibility(visibility)
                Attr.weak_sdk_frameworks(weak_sdk_frameworks)
            }
        }

        /// Builds a `j2objc_library` target.
        ///
        /// Reference: [Bazel `j2objc_library`](https://bazel.build/reference/be/objective-c#j2objc_library)
        public static func j2objc_library(
            name: String,
            deps: [Starlark.Label],
            entry_classes: [String]? = nil,
            jre_deps: Starlark.Value? = nil,
            testonly: Bool? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Objc.j2objc_library.call {
                Attr.name(name)
                Attr.deps(deps)
                Attr.entry_classes(entry_classes)
                Attr.jre_deps(jre_deps)
                Attr.testonly(testonly)
                Attr.visibility(visibility)
            }
        }

        /// Builds an `available_xcodes` target.
        ///
        /// Reference: [Bazel `available_xcodes`](https://bazel.build/reference/be/objective-c#available_xcodes)
        public static func available_xcodes(
            name: String,
            `default`: Starlark.Label,
            versions: Starlark.Value? = nil,
            testonly: Bool? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Objc.available_xcodes.call {
                Attr.name(name)
                Attr.`default`(`default`)
                Attr.versions(versions)
                Attr.testonly(testonly)
                Attr.visibility(visibility)
            }
        }

        /// Builds an `xcode_config` target.
        ///
        /// Reference: [Bazel `xcode_config`](https://bazel.build/reference/be/objective-c#xcode_config)
        public static func xcode_config(
            name: String,
            `default`: Starlark.Label? = nil,
            local_versions: Starlark.Label? = nil,
            remote_versions: Starlark.Label? = nil,
            versions: Starlark.Value? = nil,
            testonly: Bool? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Objc.xcode_config.call {
                Attr.name(name)
                Attr.`default`(`default`)
                Attr.local_versions(local_versions)
                Attr.remote_versions(remote_versions)
                Attr.versions(versions)
                Attr.testonly(testonly)
                Attr.visibility(visibility)
            }
        }

        /// Builds an `xcode_version` target.
        ///
        /// Reference: [Bazel `xcode_version`](https://bazel.build/reference/be/objective-c#xcode_version)
        public static func xcode_version(
            name: String,
            version: String,
            aliases: [String]? = nil,
            default_ios_sdk_version: String? = nil,
            default_macos_sdk_version: String? = nil,
            default_tvos_sdk_version: String? = nil,
            default_watchos_sdk_version: String? = nil,
            testonly: Bool? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Objc.xcode_version.call {
                Attr.name(name)
                Attr.version(version)
                Attr.aliases(aliases)
                Attr.default_ios_sdk_version(default_ios_sdk_version)
                Attr.default_macos_sdk_version(default_macos_sdk_version)
                Attr.default_tvos_sdk_version(default_tvos_sdk_version)
                Attr.default_watchos_sdk_version(default_watchos_sdk_version)
                Attr.testonly(testonly)
                Attr.visibility(visibility)
            }
        }
    }
}
