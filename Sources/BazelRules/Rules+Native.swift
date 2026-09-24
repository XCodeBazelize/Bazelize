//
//  Rules+Native.swift
//
//
//  The rule a prebuilt program is run through.
//

import Foundation
import Starlark

// MARK: - Rules.Native

extension Rules {
    /// https://github.com/bazelbuild/bazel-skylib/blob/main/docs/native_binary_doc.md
    public enum Native: String, LoadableRule {
        public var module: String {
            "@bazel_skylib//rules:native_binary.bzl"
        }

        case native_binary
    }
}

// MARK: - Rules.Native.Call

extension Rules.Native {
    public enum Call {
        /// Wraps an already-built executable as a runnable target.
        ///
        /// Parameters:
        /// - `name: String`
        ///   The Bazel target name.
        /// - `src: String`
        ///   The prebuilt executable.
        /// - `out: String`
        ///   What the executable is called in the output tree.
        /// - `data: Starlark.Value?`
        ///   What the program needs beside it at run time.
        public static func native_binary(
            name: String,
            src: String,
            out: String,
            data: Starlark.Value? = nil,
            tags: [String] = [],
            visibility: Starlark.Statement.Argument.Visibility? = nil)
            -> Starlark.Statement.Call
        {
            Rules.Native.native_binary.call {
                "name" => name
                "src" => Starlark.Label.named(src)
                "out" => out
                if let data {
                    "data" => data
                }
                if !tags.isEmpty {
                    "tags" => tags
                }
                if let visibility {
                    visibility
                }
            }
        }
    }
}
