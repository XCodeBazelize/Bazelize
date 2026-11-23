//
//  Commands+Plugins.swift
//
//  Running the build tool plugins of a generated workspace.
//

import Foundation
@preconcurrency import PathKit
import Subprocess
import System

extension Commands {
    /// Bazel builds the host, plugins, and tools using the workspace's own plan.
    static func runBuildToolPlugins(in workspace: Path) async throws {
        let result = try await Subprocess.run(
            .name("bazel"),
            arguments: Arguments(["run", "//:plugins"]),
            workingDirectory: FilePath(workspace.string),
            output: .discarded,
            error: .string(limit: 1024 * 1024))

        guard result.terminationStatus.isSuccess else {
            throw SwiftPM.PluginError.runFailed(Self.pluginErrors(result.standardError))
        }
    }

    private static func pluginErrors(_ output: String?) -> String {
        guard let output else { return "no output" }
        let lines = output
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.lowercased().hasPrefix("error:") }
        let reason = lines.suffix(3).joined(separator: " ")
        return reason.isEmpty ? output.suffix(400).trimmingCharacters(in: .whitespacesAndNewlines) : reason
    }
}
