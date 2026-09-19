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
        /// What one target's plugins wrote, and the directory they wrote it into:
        /// two plugins of the same target write into one directory each, and a
        /// `prebuildCommand` writes a tree, so a file is only named by where it
        /// sits under that root.
        struct Output: Sendable {
            let root: Path
            let files: [Path]
        }

        /// What kept a plugin from producing what a target expects, for the run to
        /// say out loud: the compile error a missing generated file causes names
        /// the file, never the plugin.
        let notes: [String]

        /// Keyed `<package directory>/<target>`.
        private let outputs: [String: Output]

        init(outputs: [String: Output] = [:], notes: [String] = []) {
            self.outputs = outputs
            self.notes = notes
        }

        func output(of target: String, in package: Package) -> Output? {
            outputs["\(package.directory)/\(target)"]
        }
    }

    /// Runs the plugins of the packages this project owns, and collects what they
    /// wrote.
    static func runPlugins(of packages: [Package]) async -> PluginOutputs {
        var outputs: [String: PluginOutputs.Output] = [:]
        var notes: [String] = []

        for package in packages where package.isRoot || package.isLocal {
            let targets = package.manifest.targets
                .filter { !$0.pluginUsages.isEmpty }
                .map(\.name)
            guard !targets.isEmpty else { continue }

            for target in targets {
                /// What a previous run left there is not what the plugins produce
                /// now: SwiftPM names the files it declared and leaves the rest,
                /// while everything found here is taken as the target's own.
                try? outputsRoot(of: target, in: package).delete()

                if let failure = await build(target: target, of: package) {
                    notes.append(failure)
                    continue
                }

                let produced = self.outputs(of: target, in: package)
                guard !produced.files.isEmpty else { continue }
                outputs["\(package.directory)/\(target)"] = produced
            }
        }

        return .init(outputs: outputs, notes: notes)
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
                /// What SwiftPM said is the only thing that explains this: the
                /// target failing to build is a toolchain, a network or a source
                /// problem, and none of them can be guessed from an exit code.
                error: .string(limit: 1024 * 1024))

            if result.terminationStatus.isSuccess { return nil }
            failure = Self.reason(result.standardError) ?? "swift build failed"
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

    /// What SwiftPM complained about, without the build log around it.
    private static func reason(_ error: String?) -> String? {
        guard let error else { return nil }

        let lines = error
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.lowercased().hasPrefix("error:") }

        let reason = lines.suffix(3).joined(separator: " ")
        return reason.isEmpty ? nil : reason
    }

    /// `.build/plugins/outputs/<identity>/<target>/<destination>/<plugin>/…`
    private static func outputsRoot(of target: String, in package: Package) -> Path {
        package.root + ".build/plugins/outputs" + package.identity + target
    }

    /// Every file a target's plugins wrote, not only the Swift ones: SwiftPM
    /// splits what a plugin produced into the target's sources and its resources,
    /// and a `prebuildCommand` writes a whole directory whose contents it never
    /// names.
    private static func outputs(of target: String, in package: Package) -> PluginOutputs.Output {
        let root = outputsRoot(of: target, in: package)
        guard root.isDirectory else { return .init(root: root, files: []) }

        return .init(root: root, files: Generator.walk(root).sorted())
    }
}
