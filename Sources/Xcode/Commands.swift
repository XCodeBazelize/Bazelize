import Foundation
import Subprocess

/// Toolchain queries used while loading an Xcode project.
enum Commands {
    static func installedSDKs() async throws -> [Toolchain.SDK] {
        let output = try await xcodebuild(["-showsdks", "-json"])
        return try JSONDecoder().decode([Toolchain.SDK].self, from: Data(output.utf8))
    }

    static func xcodeVersion() async throws -> String {
        try await xcodebuild(["-version"])
    }

    private static func xcodebuild(_ arguments: [String]) async throws -> String {
        let result = try await Subprocess.run(
            .path(.init("/usr/bin/xcodebuild")),
            arguments: Arguments(arguments),
            output: .string(limit: Int.max),
            error: .discarded)
        guard result.terminationStatus.isSuccess else {
            throw DiscoveryError(status: String(describing: result.terminationStatus))
        }
        return result.standardOutput
    }

    private struct DiscoveryError: Error {
        let status: String
    }
}
