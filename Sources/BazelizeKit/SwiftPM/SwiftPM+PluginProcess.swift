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

        /// Where the toolchain keeps the module a plugin is compiled against,
        /// which the rules that build a plugin need spelled out.
        ///
        /// `xcrun` is asked once: a run builds against one toolchain.
        static let pluginAPIPath: String? = {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
            process.arguments = ["--find", "swiftc"]

            let output = Pipe()
            process.standardOutput = output
            process.standardError = FileHandle.nullDevice

            guard (try? process.run()) != nil else { return nil }
            let data = output.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()

            let found = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !found.isEmpty else { return nil }

            /// `<toolchain>/usr/bin/swiftc` → `<toolchain>/usr/lib/swift/pm/PluginAPI`
            let api = Path(found).parent().parent() + "lib/swift/pm/PluginAPI"
            return api.isDirectory ? api.string : nil
        }()

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
