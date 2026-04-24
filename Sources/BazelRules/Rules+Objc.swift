//
//  Rules+Objc.swift
//
//
//  Created by Yume on 2022/7/22.
//

import Foundation
import RuleBuilder

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

public extension Rules.Objc {
    enum Call {
        /// Builds an `objc_library` target.
        ///
        /// Reference: [Bazel `objc_library`](https://bazel.build/reference/be/objective-c#objc_library)
        public static func objc_library(
            name: String,
            srcs: Starlark.Value? = nil,
            hdrs: Starlark.Value? = nil,
            deps: Starlark.Value? = nil,
            data: Starlark.Value? = nil,
            alwayslink: Bool? = nil,
            copts: [String]? = nil,
            defines: [String]? = nil,
            includes: [String]? = nil,
            linkopts: [String]? = nil,
            module_map: Starlark.Label? = nil,
            module_name: String? = nil,
            non_arc_srcs: Starlark.Value? = nil,
            pch: Starlark.Label? = nil,
            sdk_dylibs: [String]? = nil,
            sdk_frameworks: [String]? = nil,
            sdk_includes: [String]? = nil,
            textual_hdrs: Starlark.Value? = nil,
            testonly: Bool? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil,
            weak_sdk_frameworks: [String]? = nil
        ) -> Starlark.Statement.Call {
            Rules.Objc.objc_library.call {
                "name" => name
                if let srcs { "srcs" => srcs }
                if let hdrs { "hdrs" => hdrs }
                if let deps { "deps" => deps }
                if let data { "data" => data }
                if let alwayslink { "alwayslink" => alwayslink }
                if let copts { "copts" => copts }
                if let defines { "defines" => defines }
                if let includes { "includes" => includes }
                if let linkopts { "linkopts" => linkopts }
                if let module_map { "module_map" => module_map }
                if let module_name { "module_name" => module_name }
                if let non_arc_srcs { "non_arc_srcs" => non_arc_srcs }
                if let pch { "pch" => pch }
                if let sdk_dylibs { "sdk_dylibs" => sdk_dylibs }
                if let sdk_frameworks { "sdk_frameworks" => sdk_frameworks }
                if let sdk_includes { "sdk_includes" => sdk_includes }
                if let textual_hdrs { "textual_hdrs" => textual_hdrs }
                if let testonly { "testonly" => testonly }
                if let visibility { visibility }
                if let weak_sdk_frameworks { "weak_sdk_frameworks" => weak_sdk_frameworks }
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
            weak_sdk_frameworks: [String]? = nil
        ) -> Starlark.Statement.Call {
            Rules.Objc.objc_import.call {
                "name" => name
                if let archives { "archives" => archives }
                if let deps { "deps" => deps }
                if let hdrs { "hdrs" => hdrs }
                if let sdk_dylibs { "sdk_dylibs" => sdk_dylibs }
                if let sdk_frameworks { "sdk_frameworks" => sdk_frameworks }
                if let alwayslink { "alwayslink" => alwayslink }
                if let testonly { "testonly" => testonly }
                if let visibility { visibility }
                if let weak_sdk_frameworks { "weak_sdk_frameworks" => weak_sdk_frameworks }
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
            visibility: Starlark.Statement.Argument.Visibility? = nil
        ) -> Starlark.Statement.Call {
            Rules.Objc.j2objc_library.call {
                "name" => name
                "deps" => deps
                if let entry_classes { "entry_classes" => entry_classes }
                if let jre_deps { "jre_deps" => jre_deps }
                if let testonly { "testonly" => testonly }
                if let visibility { visibility }
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
            visibility: Starlark.Statement.Argument.Visibility? = nil
        ) -> Starlark.Statement.Call {
            Rules.Objc.available_xcodes.call {
                "name" => name
                "default" => `default`
                if let versions { "versions" => versions }
                if let testonly { "testonly" => testonly }
                if let visibility { visibility }
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
            visibility: Starlark.Statement.Argument.Visibility? = nil
        ) -> Starlark.Statement.Call {
            Rules.Objc.xcode_config.call {
                "name" => name
                if let `default` { "default" => `default` }
                if let local_versions { "local_versions" => local_versions }
                if let remote_versions { "remote_versions" => remote_versions }
                if let versions { "versions" => versions }
                if let testonly { "testonly" => testonly }
                if let visibility { visibility }
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
            visibility: Starlark.Statement.Argument.Visibility? = nil
        ) -> Starlark.Statement.Call {
            Rules.Objc.xcode_version.call {
                "name" => name
                "version" => version
                if let aliases { "aliases" => aliases }
                if let default_ios_sdk_version { "default_ios_sdk_version" => default_ios_sdk_version }
                if let default_macos_sdk_version { "default_macos_sdk_version" => default_macos_sdk_version }
                if let default_tvos_sdk_version { "default_tvos_sdk_version" => default_tvos_sdk_version }
                if let default_watchos_sdk_version { "default_watchos_sdk_version" => default_watchos_sdk_version }
                if let testonly { "testonly" => testonly }
                if let visibility { visibility }
            }
        }
    }
}
