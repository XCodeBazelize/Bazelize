//
//  Commands.swift
//
//  The child processes bazelize runs, named for their purpose.
//

import Foundation
import Subprocess
import System

/// External operations; callers supply intent rather than process configuration.
public enum Commands {
    public struct Failure: Error, CustomStringConvertible {
        public let command: String
        public let status: String
        /// The reason the command gave, when its standard error is kept.
        public let diagnostics: String?

        init(_ executable: String, _ arguments: [String], status: TerminationStatus, diagnostics: String? = nil) {
            command = ([executable] + arguments).joined(separator: " ")
            self.status = "\(status)"
            self.diagnostics = diagnostics
        }

        public var description: String {
            let failure = "`\(command)` failed with \(status)"
            return diagnostics.map { "\(failure): \($0)" } ?? failure
        }
    }

    /// The standard output of a command whose standard error is not of interest.
    static func text(_ executable: String, _ arguments: [String]) async throws -> String {
        let result = try await Subprocess.run(
            Self.executable(executable),
            arguments: Arguments(arguments),
            output: .string(limit: Int.max),
            error: .discarded)
        guard result.terminationStatus.isSuccess else {
            throw Failure(executable, arguments, status: result.terminationStatus)
        }
        return result.standardOutput
    }

    /// Runs a command for its effect, showing its standard error to the user.
    static func execute(_ executable: String, _ arguments: [String], in directory: FilePath) async throws {
        let result = try await Subprocess.run(
            Self.executable(executable),
            arguments: Arguments(arguments),
            workingDirectory: directory,
            output: .discarded,
            error: .currentStandardError)
        guard result.terminationStatus.isSuccess else {
            throw Failure(executable, arguments, status: result.terminationStatus)
        }
    }

    private static func executable(_ executable: String) -> Executable {
        executable.hasPrefix("/") ? .path(FilePath(executable)) : .name(executable)
    }
}
