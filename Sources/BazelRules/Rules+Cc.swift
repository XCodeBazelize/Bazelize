import Foundation
import Starlark

// MARK: - Rules.Cc

extension Rules {
    public enum Cc: String, LoadableRule {
        case cc_import
        case cc_library

        public var module: String {
            "@rules_cc//cc:defs.bzl"
        }
    }
}

// MARK: - Rules.Cc.Call

extension Rules.Cc {
    public enum Call {
        public static func cc_import(
            name: String,
            shared_library: Starlark.Label? = nil,
            static_library: Starlark.Label? = nil,
            interface_library: Starlark.Label? = nil,
            hdrs: Starlark.Value? = nil,
            system_provided: Bool? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Cc.cc_import.call {
                "name" => name
                if let shared_library { "shared_library" => shared_library }
                if let static_library { "static_library" => static_library }
                if let interface_library { "interface_library" => interface_library }
                if let hdrs { "hdrs" => hdrs }
                if let system_provided { "system_provided" => system_provided }
                if let visibility { visibility }
            }
        }

        /// Builds a `cc_library` target.
        ///
        /// Reference: [Bazel `cc_library`](https://bazel.build/reference/be/c-cpp#cc_library)
        public static func cc_library(
            name: String,
            aspect_hints: Starlark.Value? = nil,
            srcs: Starlark.Value? = nil,
            hdrs: Starlark.Value? = nil,
            deps: Starlark.Value? = nil,
            copts: [String]? = nil,
            includes: [String]? = nil,
            linkopts: [String]? = nil,
            tags: [String]? = nil,
            textual_hdrs: Starlark.Value? = nil,
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Cc.cc_library.call {
                "name" => name
                if let aspect_hints { "aspect_hints" => aspect_hints }
                if let srcs { "srcs" => srcs }
                if let hdrs { "hdrs" => hdrs }
                if let deps { "deps" => deps }
                if let copts { "copts" => copts }
                if let includes { "includes" => includes }
                if let linkopts { "linkopts" => linkopts }
                if let tags { "tags" => tags }
                if let textual_hdrs { "textual_hdrs" => textual_hdrs }
                if let visibility { visibility }
            }
        }
    }
}
