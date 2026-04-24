//
//  Rules+Config.swift
//
//
//  Created by Yume on 2022/8/5.
//

import Foundation
import RuleBuilder

/// https://github.com/bazelbuild/bazel-skylib/blob/main/docs/common_settings_doc.md
extension Rules {
    public enum Config: String, LoadableRule {
        public var module: String {
            "@bazel_skylib//rules:common_settings.bzl"
        }
        
        // MARK: - Bool
        
        case bool_flag
        case bool_setting
        
        // MARK: - Int
        
        case int_flag
        case int_setting
        
        // MARK: - String
        
        case string_flag
        case string_setting
        
        // MARK: - String List
        
        case string_list_flag
        case string_list_setting
        
        // MARK: - Provider
        
        case BuildSettingInfo
    }
}

@available(*, deprecated, renamed: "Rules.Config")
public typealias RulesConfig = Rules.Config

public extension Rules.Config {
    enum Call {
        /// Builds a `bool_flag` target.
        ///
        /// Reference: [bazel-skylib `bool_flag`](https://android.googlesource.com/platform/external/bazel-skylib/+/HEAD/docs/common_settings_doc.md#bool_flag)
        ///
        /// Parameters:
        /// - `name: String`
        ///   The Bazel target name.
        /// - `build_setting_default: Bool`
        ///   Required default value of the build setting.
        /// - `scope: String?`
        ///   Optional propagation scope, such as `"universal"`.
        /// - `visibility: Starlark.Statement.Argument.Visibility?`
        ///   Repo-local convenience for emitting a `visibility` attribute.
        public static func bool_flag(
            name: String,
            build_setting_default: Bool,
            scope: String? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil
        ) -> Starlark.Statement.Call {
            Rules.Config.bool_flag.call {
                "name" => name
                "build_setting_default" => build_setting_default
                if let scope {
                    "scope" => scope
                }
                if let visibility {
                    visibility
                }
            }
        }
        
        /// Builds a `bool_setting` target.
        ///
        /// Reference: [bazel-skylib `bool_setting`](https://android.googlesource.com/platform/external/bazel-skylib/+/HEAD/docs/common_settings_doc.md#bool_setting)
        public static func bool_setting(
            name: String,
            build_setting_default: Bool,
            scope: String? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil
        ) -> Starlark.Statement.Call {
            Rules.Config.bool_setting.call {
                "name" => name
                "build_setting_default" => build_setting_default
                if let scope {
                    "scope" => scope
                }
                if let visibility {
                    visibility.argument
                }
            }
        }
        
        /// Builds an `int_flag` target.
        ///
        /// Reference: [bazel-skylib `int_flag`](https://android.googlesource.com/platform/external/bazel-skylib/+/HEAD/docs/common_settings_doc.md#int_flag)
        public static func int_flag(
            name: String,
            build_setting_default: Int,
            scope: String? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil
        ) -> Starlark.Statement.Call {
            Rules.Config.int_flag.call {
                "name" => name
                "build_setting_default" => .int(build_setting_default)
                if let scope {
                    "scope" => scope
                }
                if let visibility {
                    visibility
                }
            }
        }
        
        /// Builds an `int_setting` target.
        ///
        /// Reference: [bazel-skylib `int_setting`](https://android.googlesource.com/platform/external/bazel-skylib/+/HEAD/docs/common_settings_doc.md#int_setting)
        public static func int_setting(
            name: String,
            build_setting_default: Int,
            scope: String? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil
        ) -> Starlark.Statement.Call {
            Rules.Config.int_setting.call {
                "name" => name
                "build_setting_default" => .int(build_setting_default)
                if let scope {
                    "scope" => scope
                }
                if let visibility {
                    visibility
                }
            }
        }
        
        /// Builds a `string_flag` target.
        ///
        /// Reference: [bazel-skylib `string_flag`](https://android.googlesource.com/platform/external/bazel-skylib/+/HEAD/docs/common_settings_doc.md#string_flag)
        public static func string_flag(
            name: String,
            build_setting_default: String,
            make_variable: String? = nil,
            scope: String? = nil,
            values: [String]? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil
        ) -> Starlark.Statement.Call {
            Rules.Config.string_flag.call {
                "name" => name
                "build_setting_default" => build_setting_default
                if let make_variable {
                    "make_variable" => make_variable
                }
                if let scope {
                    "scope" => scope
                }
                if let values {
                    "values" => values
                }
                if let visibility {
                    visibility
                }
            }
        }
        
        /// Builds a `string_setting` target.
        ///
        /// Reference: [bazel-skylib `string_setting`](https://android.googlesource.com/platform/external/bazel-skylib/+/HEAD/docs/common_settings_doc.md#string_setting)
        public static func string_setting(
            name: String,
            build_setting_default: String,
            make_variable: String? = nil,
            scope: String? = nil,
            values: [String]? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil
        ) -> Starlark.Statement.Call {
            Rules.Config.string_setting.call {
                "name" => name
                "build_setting_default" => build_setting_default
                if let make_variable {
                    "make_variable" => make_variable
                }
                if let scope {
                    "scope" => scope
                }
                if let values {
                    "values" => values
                }
                if let visibility {
                    visibility
                }
            }
        }
        
        /// Builds a `string_list_flag` target.
        ///
        /// Reference: [bazel-skylib `string_list_flag`](https://android.googlesource.com/platform/external/bazel-skylib/+/HEAD/docs/common_settings_doc.md#string_list_flag)
        public static func string_list_flag(
            name: String,
            build_setting_default: [String],
            scope: String? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil
        ) -> Starlark.Statement.Call {
            Rules.Config.string_list_flag.call {
                "name" => name
                "build_setting_default" => build_setting_default
                if let scope {
                    "scope" => scope
                }
                if let visibility {
                    visibility
                }
            }
        }
        
        /// Builds a `string_list_setting` target.
        ///
        /// Reference: [bazel-skylib `string_list_setting`](https://android.googlesource.com/platform/external/bazel-skylib/+/HEAD/docs/common_settings_doc.md#string_list_setting)
        public static func string_list_setting(
            name: String,
            build_setting_default: [String],
            scope: String? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil
        ) -> Starlark.Statement.Call {
            Rules.Config.string_list_setting.call {
                "name" => name
                "build_setting_default" => build_setting_default
                if let scope {
                    "scope" => scope
                }
                if let visibility {
                    visibility
                }
            }
        }
    }
}
