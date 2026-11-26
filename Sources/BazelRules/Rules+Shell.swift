//
//  Rules+Shell.swift
//
//
//  The rule a workspace's own scripts are run with.
//

import Foundation
import Starlark

// MARK: - Rules.Shell

extension Rules {
    /// https://github.com/bazelbuild/rules_shell
    public enum Shell: String, LoadableRule {
        public var module: String {
            "@rules_shell//shell:sh_binary.bzl"
        }

        case sh_binary
    }
}

// MARK: - Rules.Shell.Call

extension Rules.Shell {
    public enum Call {
        public static func sh_binary(
            name: String,
            srcs: [String],
            data: [String] = [],
            tags: [String] = [])
            -> Starlark.Statement.Call
        {
            Rules.Shell.sh_binary.call {
                Attr.name(name)
                Attr.srcs(srcs)
                if !data.isEmpty { Attr.data(data.map { Starlark.Label.named($0) }) }
                if !tags.isEmpty { Attr.tags(tags) }
            }
        }
    }
}
