//
//  SwiftPM+PluginProcess.swift
//
//
//  Running the build tool plugins of a generated workspace, and the toolchain
//  the rules that build one point at.
//

import Foundation
@preconcurrency import PathKit
import Subprocess
import System
import Util

extension SwiftPM {
    enum PluginHost {
        /// `bazel run //:plugins` in the workspace that was just written.
        ///
        /// Bazel builds the host, every plugin and every tool, and the host
        /// runs each request of the generated plan. A plugin therefore has one
        /// implementation of being run, which is the workspace's own: what
        /// bazelize leaves behind is what `bazel run //:plugins` produces
        /// again, whenever a plugin or its input changes.
        static func runPlugins(in workspace: Path) async throws {
            let result = try await Subprocess.run(
                .name("bazel"),
                arguments: Arguments(["run", "//:plugins"]),
                workingDirectory: FilePath(workspace.string),
                output: .discarded,
                error: .string(limit: 1024 * 1024))

            guard result.terminationStatus.isSuccess else {
                throw PluginError.runFailed(Self.errors(result.standardError))
            }
        }

        // MARK: Private

        private static func errors(_ output: String?) -> String {
            guard let output else { return "no output" }

            let lines = output
                .split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { $0.lowercased().hasPrefix("error:") }

            let reason = lines.suffix(3).joined(separator: " ")
            return reason.isEmpty ? output.suffix(400).trimmingCharacters(in: .whitespacesAndNewlines) : reason
        }
    }
}
