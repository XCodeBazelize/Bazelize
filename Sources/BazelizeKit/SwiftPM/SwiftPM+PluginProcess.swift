//
//  SwiftPM+PluginProcess.swift
//
//
//  Compiling a plugin, talking to it, and running what it asks for.
//

import Foundation
@preconcurrency import PathKit
import Subprocess
import System
import Util

extension SwiftPM {
    /// The three things a plugin host does with processes.
    enum PluginHost {
        /// Compiles a plugin target into a program.
        ///
        /// The only thing it links is the toolchain's `PackagePlugin`, which is
        /// what makes running a plugin independent of building anything else.
        static func compile(
            sources: [String],
            module: String,
            toolsVersion: String,
            to executable: Path) async throws
        {
            guard let api = pluginAPIPath else { throw PluginError.noToolchain }

            let result = try await Subprocess.run(
                .name("swiftc"),
                arguments: Arguments([
                    "-I", api,
                    "-L", api,
                    "-lPackagePlugin",
                    "-Xlinker", "-rpath", "-Xlinker", api,
                    /// Which `PackagePlugin` API the plugin was written against;
                    /// its availability is stated in terms of it.
                    "-package-description-version", toolsVersion,
                    "-parse-as-library",
                    "-module-name", module,
                    "-o", executable.string,
                ] + sources),
                output: .discarded,
                error: .string(limit: 1024 * 1024))

            guard result.terminationStatus.isSuccess else {
                throw PluginError.compileFailed(Self.errors(result.standardError))
            }
        }

        /// Asks a plugin what to run, and collects what it answers.
        ///
        /// The protocol is a length-prefixed JSON message each way over the
        /// plugin's standard input and output; its own printing goes to standard
        /// error, which is forwarded as diagnostics.
        static func ask(executable: Path, request: PluginWire.Request) async throws -> [PluginWire.Command] {
            let payload = try JSONEncoder().encode(request)

            var input = Data()
            withUnsafeBytes(of: UInt64(payload.count).littleEndian) { input.append(contentsOf: $0) }
            input.append(payload)

            let result = try await Subprocess.run(
                .path(FilePath(executable.string)),
                input: .data(input),
                output: .data(limit: 64 * 1024 * 1024),
                error: .string(limit: 1024 * 1024))

            var commands: [PluginWire.Command] = []
            for response in try messages(in: Data(result.standardOutput)) {
                switch response {
                case .build(let command):
                    commands.append(command)
                case .prebuild(let command, let directory):
                    try Path(URL(string: directory)?.path ?? directory).mkpath()
                    commands.append(command)
                case .diagnostic(let severity, let message):
                    Log.codeGenerate.warning("plugin \(severity, privacy: .public): \(message, privacy: .public)")
                case .progress, .unsupported:
                    continue
                }
            }

            guard result.terminationStatus.isSuccess || !commands.isEmpty else {
                throw PluginError.compileFailed(Self.errors(result.standardError))
            }

            return commands
        }

        /// Runs one command a plugin asked for.
        static func run(_ command: PluginWire.Command) async throws {
            let executable = Self.path(command.executable)
            let overrides = command.environment.reduce(into: [Subprocess.Environment.Key: String?]()) { all, entry in
                guard let key = Subprocess.Environment.Key(rawValue: entry.key) else { return }
                all[key] = entry.value
            }

            let result = try await Subprocess.run(
                .path(FilePath(executable)),
                arguments: Arguments(command.arguments.map(Self.path)),
                environment: .inherit.updating(overrides),
                workingDirectory: command.workingDirectory.map { FilePath(Self.path($0)) },
                output: .discarded,
                error: .string(limit: 1024 * 1024))

            guard result.terminationStatus.isSuccess else {
                throw PluginError.compileFailed(
                    "\(command.displayName ?? Path(executable).lastComponent): \(Self.errors(result.standardError))")
            }
        }

        /// Builds the product that holds a plugin's tool.
        static func build(product: String, of package: Path) async throws -> Path? {
            let build = try await Subprocess.run(
                .name("swift"),
                arguments: Arguments(["build", "--package-path", package.string, "--product", product]),
                output: .discarded,
                error: .string(limit: 1024 * 1024))

            guard build.terminationStatus.isSuccess else {
                throw PluginError.compileFailed("the plugin's tool does not build: \(Self.errors(build.standardError))")
            }

            let directory = try await Subprocess.run(
                .name("swift"),
                arguments: Arguments(["build", "--package-path", package.string, "--show-bin-path"]),
                output: .string(limit: 64 * 1024),
                error: .discarded)

            guard
                let path = Optional(directory.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines)),
                !path.isEmpty
            else {
                return nil
            }

            let tool = Path(path) + product
            return tool.exists ? tool : nil
        }

        // MARK: Private

        /// A plugin speaks in file URLs; a command line takes paths.
        private static func path(_ value: String) -> String {
            guard value.hasPrefix("file://") else { return value }
            return URL(string: value)?.path ?? value
        }

        private static func messages(in data: Data) throws -> [PluginWire.Response] {
            var responses: [PluginWire.Response] = []
            var offset = data.startIndex

            while offset + 8 <= data.endIndex {
                let header = data[offset ..< offset + 8]
                let count = Int(header.reduce(UInt64(0)) { total, byte in
                    (total >> 8) | (UInt64(byte) << 56)
                }.littleEndian)

                let start = offset + 8
                guard count > 0, start + count <= data.endIndex else {
                    throw PluginError.undecodable("a message claims \(count) bytes and the stream has fewer")
                }

                let payload = data[start ..< start + count]
                do {
                    responses.append(try JSONDecoder().decode(PluginWire.Response.self, from: payload))
                } catch {
                    throw PluginError.undecodable("\(error)")
                }

                offset = start + count
            }

            return responses
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
