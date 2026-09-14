//
//  BazelRC.swift
//
//
//  Created by Yume on 2022/12/8.
//

import Foundation
import PathKit

extension Bazel {
    /// [config](https://bazel.build/docs/configurable-attributes)
    /// [.bazelrc](https://bazel.build/run/bazelrc)
    ///
    ///
    /// TODO:
    /// TIP: `import %workspace%/config.bazelrc` in `.bazelrc`
    ///
    /// /config.bazelrc
    struct BazelRC: BazelFile {
        let path: Path
        private(set) var code = ""

        init(_ root: Path) {
            path = root + "config.bazelrc"
        }

        /// build:debug --//:mode=debug
        /// bazel build --config=debug [PACKAGE:RULE]
        mutating
        func setup(config: [String : BuildSettings]?, targets: [Target]) {
            let configs = config?.keys.map { $0 } ?? []
            let modes = configs.map { config in
                "build:\(config) --//:mode=\(config)"
            }.sorted()

            code = (Self.minimumOSFlags(targets: targets) + modes).withNewLine
        }

        /// Xcode resolves deployment targets per target; Bazel needs a default for
        /// everything outside a bundle rule's transition, otherwise SwiftPM
        /// dependencies fail analysis against Bazel's own (much older) defaults.
        private static func minimumOSFlags(targets: [Target]) -> [String] {
            let platforms: [(flag: String, keyPath: KeyPath<BuildSettings, String?>)] = [
                ("ios_minimum_os", \.platform.iOS),
                ("macos_minimum_os", \.platform.macOS),
                ("tvos_minimum_os", \.platform.tvOS),
                ("watchos_minimum_os", \.platform.watchOS),
            ]

            return platforms.compactMap { platform in
                let versions = targets.compactMap { target in
                    target.prefer(platform.keyPath)
                }
                guard let highest = versions.max(by: Self.isOlder) else { return nil }
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

extension Bazel {
    /// /.bazelrc
    ///
    /// Bazel only reads `config.bazelrc` when the root `.bazelrc` imports it, so
    /// the generated flags are inert without this file.
    struct RootRC {
        static let importLine = "import %workspace%/config.bazelrc"

        let path: Path

        init(_ root: Path) {
            path = root + ".bazelrc"
        }

        /// Creates `.bazelrc` when missing and otherwise appends the import once,
        /// because the file may be hand-written and carry unrelated flags.
        func ensureImport() throws {
            guard let existing = try? String(contentsOfFile: path.string, encoding: .utf8) else {
                try path.write(Self.importLine + "\n")
                return
            }

            guard !existing.components(separatedBy: .newlines).contains(Self.importLine) else { return }

            let separator = existing.hasSuffix("\n") || existing.isEmpty ? "" : "\n"
            try path.write(existing + separator + Self.importLine + "\n")
        }
    }
}
