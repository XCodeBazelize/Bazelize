//
//  SwiftPM+Generator+Glob.swift
//
//
//  What a rule names, globs and excludes, and the glob semantics behind it.
//

import BazelRules
import Foundation
@preconcurrency import PathKit
import Starlark
import Util

extension SwiftPM.Generator {
    /// The sources of a target: what this run wrote, named, plus what the
    /// target's own directory has, globbed.
    ///
    /// The glob's `allow_empty` is there for a plugin's directory, which is
    /// written by `bazel run //:plugins` after the rules are — and it would
    /// cover a missing accessor just as quietly. A file this run wrote is a
    /// file that is there, so it is named: absent, it is an error about the
    /// file rather than a module that mysteriously has no `Bundle.module`.
    func sources(
        naming written: [String],
        globbing patterns: [String],
        excluding excluded: [String]) -> Starlark.Value
    {
        let named = written.filter { path in
            !patterns.contains { Self.matches($0, path) }
        }

        return files(
            naming: named,
            matching: patterns,
            excluding: excluded,
            allowEmpty: true)
    }

    /// Patterns as an attribute value: a pattern with no wildcard in it is
    /// a file, and `glob(["a/b.swift"])` is that file with a way to be
    /// silently empty instead — which buildifier's `constant-glob` says out
    /// loud.
    ///
    /// These patterns are matched against what is on disk before they get
    /// here, so naming one cannot name a file that is not there.
    func files(
        naming written: [String] = [],
        matching patterns: [String],
        excluding excluded: [String] = [],
        allowEmpty: Bool = false) -> Starlark.Value
    {
        let wildcards = patterns.filter { $0.contains(where: Self.isWildcard) }
        /// A file a wildcard already covers would be named twice, and a
        /// file the glob excludes is not part of the target at all.
        let constants = patterns.filter { pattern in
            !pattern.contains(where: Self.isWildcard)
                && !wildcards.contains { Self.matches($0, pattern) }
                && !excluded.contains { Self.matches($0, pattern) }
        }

        return Starlark.paths(
            written + constants + wildcards,
            exclude: excluded,
            allowEmpty: allowEmpty)
    }

    private static func isWildcard(_ character: Character) -> Bool {
        character == "*" || character == "?" || character == "["
    }

    /// The patterns that match at least one of the target's files.
    ///
    /// Bazel fails a glob that matches nothing, so a pattern for a file type
    /// the target does not have would break the package rather than produce an
    /// empty list.
    func matching(_ patterns: [String], _ files: [String]) -> [String] {
        patterns.filter { pattern in
            files.contains { Self.matches(pattern, $0) }
        }
    }

    /// Bazel's own glob semantics, on path segments: `**` stands for any run
    /// of segments, `*` for any part of one.
    static func matches(_ pattern: String, _ file: String) -> Bool {
        matches(
            pattern: pattern.split(separator: "/").map(String.init),
            file: file.split(separator: "/").map(String.init))
    }

    private static func matches(pattern: [String], file: [String]) -> Bool {
        guard let segment = pattern.first else { return file.isEmpty }

        if segment == "**" {
            let rest = Array(pattern.dropFirst())
            if matches(pattern: rest, file: file) { return true }
            guard !file.isEmpty else { return false }
            return matches(pattern: pattern, file: Array(file.dropFirst()))
        }

        guard let name = file.first, matches(segment: segment, name: name) else {
            return false
        }
        return matches(pattern: Array(pattern.dropFirst()), file: Array(file.dropFirst()))
    }

    private static func matches(segment: String, name: String) -> Bool {
        let parts = segment.split(separator: "*", omittingEmptySubsequences: false).map(String.init)
        guard parts.count > 1 else { return segment == name }

        var rest = Substring(name)
        for (index, part) in parts.enumerated() where !part.isEmpty {
            if index == 0 {
                guard rest.hasPrefix(part) else { return false }
                rest = rest.dropFirst(part.count)
            } else if index == parts.count - 1 {
                guard rest.hasSuffix(part) else { return false }
                rest = rest.dropLast(part.count)
            } else {
                guard let range = rest.range(of: part) else { return false }
                rest = rest[range.upperBound...]
            }
        }

        return true
    }

    /// An explicit `sources` list names files or directories; without one the
    /// whole target directory is the target.
    func sources(of target: SwiftPM.PackageTarget, prefix: String, extensions: [String]) -> [String] {
        guard let sources = target.sources, !sources.isEmpty else {
            return extensions.map { "\(prefix)/**/*.\($0)" }
        }

        return sources.flatMap { source -> [String] in
            guard let fileExtension = Path(source).extension else {
                return extensions.map { "\(prefix)/\(source)/**/*.\($0)" }
            }
            return extensions.contains(fileExtension) ? ["\(prefix)/\(source)"] : []
        }
    }

    /// `exclude` names a file or a directory; a directory excludes everything
    /// under it.
    ///
    /// Documentation catalogues are excluded on top of that: SwiftPM ignores a
    /// `.docc` directory, and the sample code inside one does not compile —
    /// it is written against `PackageDescription`.
    /// A manifest may write a directory with a trailing slash, which Bazel
    /// rejects as an empty segment once a pattern is appended to it.
    func excluded(_ target: SwiftPM.PackageTarget, prefix: String) -> [String] {
        target.exclude.flatMap { excluded -> [String] in
            let path = Path(excluded).normalize().string
            return Path(excluded).extension == nil
                ? ["\(prefix)/\(path)/**"]
                : ["\(prefix)/\(path)"]
        } + Self.ignoredExtensions.map { "\(prefix)/**/*.\($0)/**" }
    }

    /// Directory types SwiftPM's file rules ignore.
    static let ignoredExtensions = ["docc", "xcprivacy"]
}
