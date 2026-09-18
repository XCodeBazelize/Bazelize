//
//  SwiftPM+Plugin.swift
//
//
//  The sources a build tool plugin generates.
//

import Foundation
@preconcurrency import PathKit
import Subprocess
import Util

extension SwiftPM {
    /// What a build tool plugin produced, by target.
    ///
    /// A plugin is a program the compiler host asks for build commands over a
    /// private protocol, so bazelize does not run it: SwiftPM does, and leaves the
    /// result under `.build/plugins/outputs`. Those files are taken as they are,
    /// the way every other thing SwiftPM already produced is.
    ///
    /// The consequence is the one every generated file here has: they change when
    /// bazelize runs again, not when the input changes. That is also why only a
    /// package in the project's own repository is built — running a plugin means
    /// building its package with SwiftPM, and doing that for every dependency that
    /// merely lints would make generating a workspace cost a full SwiftPM build.
    struct PluginOutputs: Sendable {
        /// What kept a plugin from producing what a target expects, for the run to
        /// say out loud: the compile error a missing generated file causes names
        /// the file, never the plugin.
        let notes: [String]

        /// Keyed `<package directory>/<target>`.
        private let files: [String: [Path]]

        init(files: [String: [Path]] = [:], notes: [String] = []) {
            self.files = files
            self.notes = notes
        }

        func files(of target: String, in package: Package) -> [Path] {
            files["\(package.directory)/\(target)"] ?? []
        }
    }

    /// Runs the plugins of the packages this project owns, and collects what they
    /// wrote.
    static func runPlugins(of packages: [Package]) async -> PluginOutputs {
        var files: [String: [Path]] = [:]
        var notes: [String] = []

        for package in packages where package.isRoot || package.isLocal {
            let targets = package.manifest.targets
                .filter { !$0.pluginUsages.isEmpty }
                .map(\.name)
            guard !targets.isEmpty else { continue }

            for target in targets {
                if let failure = await build(target: target, of: package) {
                    notes.append(failure)
                    continue
                }

                let produced = outputs(of: target, in: package)
                guard !produced.isEmpty else { continue }
                files["\(package.directory)/\(target)"] = produced
            }
        }

        return .init(files: files, notes: notes)
    }

    // MARK: Private

    /// Building the target is what makes SwiftPM run its plugins; there is no
    /// command that only runs them.
    ///
    /// Returns why the plugins did not run, or `nil` when they did.
    private static func build(target: String, of package: Package) async -> String? {
        let failure: String
        do {
            let result = try await Subprocess.run(
                .name("swift"),
                arguments: Arguments([
                    "build",
                    "--package-path", package.root.string,
                    "--target", target,
                ]),
                output: .discarded,
                error: .discarded)

            if result.terminationStatus.isSuccess { return nil }
            failure = "swift build failed"
        } catch {
            failure = error.localizedDescription
        }

        let message = """
        \(package.directory)/\(target) did not run its plugins: \(failure). \
        The target is built with SwiftPM to run them, so whatever they generate \
        is missing from it.
        """
        Log.codeGenerate.warning("\(message, privacy: .public)")
        return message
    }

    /// `.build/plugins/outputs/<identity>/<target>/<destination>/<plugin>/…`
    private static func outputs(of target: String, in package: Package) -> [Path] {
        let root = package.root + ".build/plugins/outputs" + package.identity + target
        guard root.isDirectory else { return [] }

        return Generator.walk(root).filter { file in
            file.extension == "swift"
        }.sorted()
    }
}
