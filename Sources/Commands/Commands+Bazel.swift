//
//  Commands+Bazel.swift
//
//  Running the build tool plugins in a generated workspace.
//

import Foundation
@preconcurrency import PathKit
import Subprocess
import System

extension Commands.bazel {
    /// Bazel builds the host, plugins, and tools using the workspace's own plan.
    public static func runBuildToolPlugins(in workspace: Path) async throws {
        let arguments = ["run", "//:plugins"]
        let result = try await Subprocess.run(
            .name("bazel"),
            arguments: Arguments(arguments),
            workingDirectory: FilePath(workspace.string),
            output: .discarded,
            error: .string(limit: 1024 * 1024))

        guard result.terminationStatus.isSuccess else {
            throw Commands.Failure(
                "bazel", arguments,
                status: result.terminationStatus,
                diagnostics: pluginErrors(result.standardError))
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
