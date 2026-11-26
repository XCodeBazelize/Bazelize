//
//  Commands+SwiftPM.swift
//
//  Resolving Swift packages and reading what they declare.
//

import Foundation
@preconcurrency import PathKit
import Subprocess
import System
import Util

extension Commands {
    public static func resolvePackage(in directory: Path) async throws {
        Log.codeGenerate.info("swift package resolve at \(directory.string, privacy: .public)")
        try await execute("swift", ["package", "resolve"], in: FilePath(directory.string))
    }

    public static func packageManifest(at directory: Path) async throws -> Data {
        let arguments = ["package", "dump-package", "--package-path", directory.string]
        let result = try await Subprocess.run(
            .name("swift"),
            arguments: Arguments(arguments),
            output: .data(limit: 32 * 1024 * 1024),
            error: .discarded)
        guard result.terminationStatus.isSuccess else {
            throw Failure("swift", arguments, status: result.terminationStatus)
        }
        return result.standardOutput
    }

    public static func pkgConfigCFlags(package: String) async throws -> [String] {
        try await text("pkg-config", ["--cflags", package]).split(whereSeparator: \.isWhitespace).map(String.init)
    }

    public static func pkgConfigLinkerFlags(package: String) async throws -> [String] {
        try await text("pkg-config", ["--libs", package]).split(whereSeparator: \.isWhitespace).map(String.init)
    }

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
            throw Failure(
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
