import Foundation
import Starlark

// MARK: - Rules.Builtin

extension Rules {
    public enum Builtin {
        public enum Call { }
    }
}

extension Rules.Builtin.Call {
    public static func config_setting(
        name: String,
        values: [String: String]? = nil,
        flag_values: [String: String]? = nil,
        visibility: Starlark.Statement.Argument.Visibility? = nil)
        -> Starlark.Statement.Call
    {
        .init("config_setting") {
            "name" => name
            if let values {
                "values" => values
            }
            if let flag_values {
                "flag_values" => flag_values
            }
            if let visibility {
                visibility.argument
            }
        }
    }

    public static func bazel_dep(
        name: String,
        version: String,
        repo_name: String? = nil)
        -> Starlark.Statement.Call
    {
        .init("bazel_dep") {
            "name" => name
            "version" => version
            if let repo_name {
                "repo_name" => repo_name
            }
        }
    }

    public static func filegroup(
        name: String,
        srcs: Starlark.Value,
        visibility: Starlark.Statement.Argument.Visibility? = nil)
        -> Starlark.Statement.Call
    {
        .init("filegroup") {
            "name" => name
            "srcs" => srcs
            if let visibility {
                visibility.argument
            }
        }
    }

    public static func genrule(
        name: String,
        srcs: Starlark.Value,
        outs: [String],
        cmd: String,
        visibility: Starlark.Statement.Argument.Visibility? = nil)
        -> Starlark.Statement.Call
    {
        .init("genrule") {
            "name" => name
            "srcs" => srcs
            "outs" => outs
            "cmd" => Starlark.custom("\"\"\"\(cmd)\"\"\"")
            if let visibility {
                visibility.argument
            }
        }
    }

    public static func alias(
        name: String,
        actual: Starlark.Label,
        tags: [String]? = nil,
        visibility: Starlark.Statement.Argument.Visibility? = nil)
        -> Starlark.Statement.Call
    {
        .init("alias") {
            "name" => name
            "actual" => actual
            if let tags { "tags" => tags }
            if let visibility {
                visibility.argument
            }
        }
    }
}
