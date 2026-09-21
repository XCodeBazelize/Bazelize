//
//  Rules+Selects.swift
//
//
//  The skylib helper for a condition that several settings satisfy.
//

import Foundation
import Starlark

// MARK: - Rules.Selects

/// https://github.com/bazelbuild/bazel-skylib/blob/main/docs/selects_doc.md
extension Rules {
    public enum Selects: String, LoadableRule {
        public var module: String {
            "@bazel_skylib//lib:selects.bzl"
        }

        /// The symbol the module exports; the rule below is a member of it.
        case selects
    }
}

// MARK: - Rules.Selects.Call

extension Rules.Selects {
    public enum Call {
        /// A `config_setting` that holds when any of the given ones does.
        public static func config_setting_group(
            name: String,
            match_any: [String]) -> Starlark.Statement.Call
        {
            .init("selects.config_setting_group") {
                "name" => name
                "match_any" => match_any.map { Starlark.Label.named($0) }
            }
        }
    }
}
