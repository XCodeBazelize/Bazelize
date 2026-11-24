import Foundation
@preconcurrency import PathKit
import Subprocess
import System
import Util

enum Commands {
    static func clonePluginRepository(url: String, name: String, in directory: Path) async throws {
        try await execute("git", ["clone", url, name], in: directory)
    }

    static func checkoutPluginRevision(_ revision: String, in repository: Path) async throws {
        try await execute("git", ["checkout", revision], in: repository)
    }

    static func buildReleasePlugin(in repository: Path) async throws {
        try await execute("swift", ["build", "-c", "release"], in: repository)
    }

    private static func execute(_ executable: String, _ arguments: [String], in directory: Path) async throws {
        Log.pluginLoader.info("\(directory.string)> \(executable) \(arguments.joined(separator: " "))")
        let result = try await Subprocess.run(
            .name(executable), arguments: Arguments(arguments),
            workingDirectory: FilePath(directory.string),
            output: .discarded, error: .currentStandardError)
        guard result.terminationStatus.isSuccess else {
            throw CommandError(
                command: ([executable] + arguments).joined(separator: " "),
                status: result.terminationStatus)
        }
    }
}
