//
//  BazelRC.swift
//
//
//  Created by Yume on 2022/12/8.
//

import Foundation
import PathKit

// MARK: - Bazel.BazelRC

extension Bazel {
    /// [config](https://bazel.build/docs/configurable-attributes)
    /// [.bazelrc](https://bazel.build/run/bazelrc)
    ///
    /// /config.bazelrc, which the generated `.bazelrc` imports.
    struct BazelRC: BazelFile {
        let path: Path
        private(set) var code = ""

        init(_ root: Path) {
            path = root + "config.bazelrc"
        }

        /// build:debug --//:mode=debug
        /// bazel build --config=debug [PACKAGE:RULE]
        mutating
        func setup(
            project: borrowing Project,
            packages: [String: String] = [:])
        {
            let configs = project.config?.keys.map { $0 } ?? []
            let modes = configs.map { config in
                "build:\(config) --//:mode=\(config)"
            }.sorted()

            code = (Self.defaults
                + Self.minimumOSFlags(project: project, packages: packages)
                + modes).withNewLine
        }

        /// Clang finds an imported framework's module map inside the framework, which
        /// is how `@import Sparkle;` compiles in Xcode. Bazel stopped passing those
        /// module maps to a compile action, so an `objc_library` that imports a
        /// framework module no longer builds; this restores it.
        private static let defaults = [
            "build --define=apple.incompatible.objc_framework_propagate_modulemap=true",
        ]

        /// Xcode resolves deployment targets per target; Bazel needs a default for
        /// everything outside a bundle rule's transition, otherwise SwiftPM
        /// dependencies fail analysis against Bazel's own (much older) defaults.
        ///
        /// The project's own targets decide it where there are any: a package
        /// that asks for more than the project is reported rather than allowed
        /// to raise everything else. A package graph handed in directly has no
        /// project targets to read, and then the graph's own floor is the
        /// answer — without one, every target compiles against the SDK's
        /// default, where a back-port the graph still reaches is unavailable.
        private static func minimumOSFlags(
            project: borrowing Project,
            packages: [String: String])
            -> [String]
        {
            let platforms: [(flag: String, platform: String, keyPath: KeyPath<BuildSettings, String?>)] = [
                ("ios_minimum_os", "ios", \.platform.iOS),
                ("macos_minimum_os", "macos", \.platform.macOS),
                ("tvos_minimum_os", "tvos", \.platform.tvOS),
                ("watchos_minimum_os", "watchos", \.platform.watchOS),
            ]

            return platforms.compactMap { platform in
                let versions = project.mapTargets { target in
                    target.prefer(platform.keyPath)
                }.compactMap { $0 }
                guard let highest = versions.max(by: Self.isOlder) ?? packages[platform.platform] else {
                    return nil
                }
                return "build --\(platform.flag)=\(highest)"
            }
        }

        private static func isOlder(_ lhs: String, _ rhs: String) -> Bool {
            let left = lhs.split(separator: ".").compactMap { Int($0) }
            let right = rhs.split(separator: ".").compactMap { Int($0) }

            for (l, r) in zip(left, right) where l != r {
                return l < r
            }
            return left.count < right.count
        }
    }
}

// MARK: - Bazel.RootRC

extension Bazel {
    /// /.bazelrc
    ///
    /// Bazel only reads `config.bazelrc` when the root `.bazelrc` imports it, so
    /// the generated flags are inert without this file.
    struct RootRC {
        /// What the root file has to import for the generated flags to be
        /// read: the project's configurations, the traits of its packages, and
        /// the localizations they ship.
        static let importLines = [
            "import %workspace%/config.bazelrc",
            "import %workspace%/traits.bazelrc",
            "import %workspace%/languages.bazelrc",
            "import %workspace%/cache.bazelrc",
        ]
        static let userImport = "try-import %workspace%/user.bazelrc"

        let path: Path

        init(_ root: Path) {
            path = root + ".bazelrc"
        }

        /// Keeps project-owned lines, normalizes owned imports once, and loads
        /// optional user overrides after all generated settings.
        func ensureImport() throws {
            let existing = (try? String(contentsOfFile: path.string, encoding: .utf8)) ?? ""
            let lines = existing.components(separatedBy: .newlines)
            let generated = Set(Self.importLines)
            var imported: Set<String> = []
            let project = lines.filter { line in
                let statement = line.trimmingCharacters(in: .whitespaces)
                if statement == Self.userImport { return false }
                return !generated.contains(statement) || imported.insert(statement).inserted
            }.joined(separator: "\n")
            let missing = Self.importLines.filter { !imported.contains($0) }
            let imports = (missing + [Self.userImport]).joined(separator: "\n")
            let separator = project.hasSuffix("\n") || project.isEmpty ? "" : "\n"
            let updated = project + separator + imports + "\n"
            if updated != existing { try path.write(updated) }
        }
    }
}
