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

extension Commands.swiftpm {
    public static func resolvePackage(in directory: Path) async throws {
        Log.codeGenerate.info("swift package resolve at \(directory.string, privacy: .public)")
        try await Commands.execute("swift", ["package", "resolve"], in: FilePath(directory.string))
    }

    public static func packageManifest(at directory: Path) async throws -> Data {
        let arguments = ["package", "dump-package", "--package-path", directory.string]
        let result = try await Subprocess.run(
            .name("swift"),
            arguments: Arguments(arguments),
            output: .data(limit: 32 * 1024 * 1024),
            error: .discarded)
        guard result.terminationStatus.isSuccess else {
            throw Commands.Failure("swift", arguments, status: result.terminationStatus)
        }
        return result.standardOutput
    }
}
