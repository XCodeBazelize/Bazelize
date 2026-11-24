import Foundation
@preconcurrency import PathKit
import Subprocess
import System
import Util

/// External operations; callers supply intent rather than process configuration.
enum Commands {
    struct Failure: Error, CustomStringConvertible {
        let command: String
        let status: String

        var description: String { "`\(command)` failed with \(status)" }
    }

    static func showSDK(sdk: String) async throws -> Path {
        Path(try await text("/usr/bin/xcrun", ["--sdk", sdk, "--show-sdk-path"])
            .trimmingCharacters(in: .whitespacesAndNewlines))
    }

    static func sdkPlatform(sdk: String) async throws -> Path {
        Path(try await text("xcrun", ["--sdk", sdk, "--show-sdk-platform-path"])
            .trimmingCharacters(in: .whitespacesAndNewlines))
    }

    static func binaryBuildInfo(at binary: Path) async throws -> String {
        try await text("xcrun", ["vtool", "-show-build", binary.string])
    }

    static func resolvePackage(in directory: Path) async throws {
        Log.codeGenerate.info("swift package resolve at \(directory.string, privacy: .public)")
        let result = try await Subprocess.run(
            .name("swift"), arguments: ["package", "resolve"],
            workingDirectory: FilePath(directory.string),
            output: .discarded, error: .currentStandardError)
        guard result.terminationStatus.isSuccess else {
            throw SwiftPMError.resolveFailed(status: "\(result.terminationStatus)")
        }
    }

    static func packageManifest(at directory: Path) async throws -> Data {
        let result = try await Subprocess.run(
            .name("swift"),
            arguments: Arguments(["package", "dump-package", "--package-path", directory.string]),
            output: .data(limit: 32 * 1024 * 1024), error: .discarded)
        guard result.terminationStatus.isSuccess else {
            throw Failure(command: "swift package dump-package", status: "\(result.terminationStatus)")
        }
        return result.standardOutput
    }

    static func pkgConfigCFlags(package: String) async throws -> [String] {
        try await text("pkg-config", ["--cflags", package]).split(whereSeparator: \.isWhitespace).map(String.init)
    }

    static func pkgConfigLinkerFlags(package: String) async throws -> [String] {
        try await text("pkg-config", ["--libs", package]).split(whereSeparator: \.isWhitespace).map(String.init)
    }

    private static func text(_ executable: String, _ arguments: [String]) async throws -> String {
        let result = try await Subprocess.run(
            executable.hasPrefix("/") ? .path(FilePath(executable)) : .name(executable),
            arguments: Arguments(arguments), output: .string(limit: Int.max), error: .discarded)
        guard result.terminationStatus.isSuccess else {
            throw Failure(
                command: ([executable] + arguments).joined(separator: " "),
                status: "\(result.terminationStatus)")
        }
        return result.standardOutput
    }
}
