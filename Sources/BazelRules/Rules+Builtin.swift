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
            Attr.name(name)
            Attr.values(values)
            Attr.flag_values(flag_values)
            Attr.visibility(visibility)
        }
    }

    public static func constraint_setting(
        name: String,
        visibility: Starlark.Statement.Argument.Visibility? = nil)
        -> Starlark.Statement.Call
    {
        .init("constraint_setting") {
            Attr.name(name)
            Attr.visibility(visibility)
        }
    }

    public static func constraint_value(
        name: String,
        constraint_setting: String,
        visibility: Starlark.Statement.Argument.Visibility? = nil)
        -> Starlark.Statement.Call
    {
        .init("constraint_value") {
            Attr.name(name)
            Attr.constraint_setting(Starlark.Label.named(constraint_setting))
            Attr.visibility(visibility)
        }
    }

    /// The `module(...)` directive every `MODULE.bazel` opens with.
    public static func module(
        name: String,
        version: String)
        -> Starlark.Statement.Call
    {
        .init("module") {
            Attr.name(name)
            Attr.version(version)
        }
    }

    public static func bazel_dep(
        name: String,
        version: String,
        repo_name: String? = nil)
        -> Starlark.Statement.Call
    {
        .init("bazel_dep") {
            Attr.name(name)
            Attr.version(version)
            Attr.repo_name(repo_name)
        }
    }

    /// Pins `module_name` to `version`, optionally patched.
    public static func single_version_override(
        module_name: String,
        version: String,
        patches: [String]? = nil,
        patch_strip: Int? = nil)
        -> Starlark.Statement.Call
    {
        .init("single_version_override") {
            Attr.module_name(module_name)
            Attr.version(version)
            Attr.patches(patches)
            Attr.patch_strip(patch_strip)
        }
    }

    public static func filegroup(
        name: String,
        srcs: Starlark.Value,
        visibility: Starlark.Statement.Argument.Visibility? = nil)
        -> Starlark.Statement.Call
    {
        .init("filegroup") {
            Attr.name(name)
            Attr.srcs(srcs)
            Attr.visibility(visibility)
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
            Attr.name(name)
            Attr.srcs(srcs)
            Attr.outs(outs)
            Attr.cmd(Starlark.custom("\"\"\"\(cmd)\"\"\""))
            Attr.visibility(visibility)
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
            Attr.name(name)
            Attr.actual(actual)
            Attr.tags(tags)
            Attr.visibility(visibility)
        }
    }
}
