//
//  SwiftPM+PluginRunnerSource.swift
//
//
//  The self-contained host built by a generated workspace.
//

import Foundation

extension SwiftPM.Generator {
    /// A small SwiftPM build-tool-plugin host compiled by Bazel in the generated
    /// workspace. The invocation plan is generated separately; this program only
    /// speaks the plugin wire protocol and runs the commands returned over it.
    static let pluginRunnerSource = #"""
    import Foundation
    import Subprocess
    import System

    private struct Invocation: Decodable {
        let package: String
        let target: String
        let plugin: String
        let executable: String
        let output: String
        let resetOutput: Bool
        let request: String
    }

    private struct CommandInvocation: Decodable {
        let plugin: String
        let executable: String
        let request: String
    }


    private struct RunnerError: Error, CustomStringConvertible {
        let description: String
    }

    @main
    private enum PluginHost {
        static func main() async {
            do {
                try await run()
            } catch {
                FileHandle.standardError.write(Data("plugin host: \(error)\n".utf8))
                exit(1)
            }
        }

        private static func run() async throws {
            var arguments = Array(CommandLine.arguments.dropFirst())

            if arguments.first == "--command" {
                arguments.removeFirst()
                guard arguments.count >= 2 else {
                    throw RunnerError(description: "expected --command REQUEST RUNFILES [arguments...]")
                }
                let request = URL(fileURLWithPath: arguments[0])
                let runfiles = arguments[1]
                try await perform(
                    try JSONDecoder().decode(CommandInvocation.self, from: Data(contentsOf: request)),
                    runfiles: runfiles,
                    arguments: Array(arguments.dropFirst(2)))
                return
            }

            guard arguments.count == 2 else {
                throw RunnerError(description: "expected PLAN RUNFILES")
            }

            let plan = URL(fileURLWithPath: arguments[0])
            let runfiles = arguments[1]
            let invocations = try JSONDecoder().decode([Invocation].self, from: Data(contentsOf: plan))

            for invocation in invocations {
                do {
                    try await run(invocation, runfiles: runfiles)
                } catch {
                    let subject = "\(invocation.package)/\(invocation.target)"
                    let reason = "did not run the \(invocation.plugin) plugin: \(error)."
                    print("\(subject) \(reason) Whatever that plugin generates is missing from the target.")
                }
            }
        }

        /// One command plugin, with what the user typed after `--`.
        ///
        /// A command plugin writes wherever it was allowed to — here, wherever
        /// `bazel run` left the process, which is the workspace the user ran it
        /// from. What it prints is its own output, so it goes straight through.
        private static func perform(
            _ invocation: CommandInvocation,
            runfiles: String,
            arguments: [String]) async throws
        {
            guard let encoded = Data(base64Encoded: invocation.request) else {
                throw RunnerError(description: "the generated request is not base64")
            }

            let decoded = try JSONSerialization.jsonObject(with: encoded)
            let replaced = replacingRunfiles(in: decoded, with: runfiles)
            guard
                var request = replaced as? [String: Any],
                var body = request["performCommand"] as? [String: Any]
            else {
                throw RunnerError(description: "the generated request is not a command")
            }
            body["arguments"] = arguments
            request["performCommand"] = body
            let payload = try JSONSerialization.data(withJSONObject: request)

            var length = UInt64(payload.count).littleEndian
            var input = withUnsafeBytes(of: &length) { Data($0) }
            input.append(payload)

            let executable = URL(fileURLWithPath: runfiles).appendingPathComponent(invocation.executable).path
            let result = try await Commands.runPlugin(executable: executable, input: input)
            /// What the plugin printed. `PackagePlugin` keeps the wire protocol
            /// on standard output and sends the plugin's own printing to
            /// standard error; `swift package <verb>` shows it on standard
            /// output, so it arrives there here too.
            if !result.error.isEmpty {
                FileHandle.standardOutput.write(Data(result.error.utf8))
            }

            for message in try messages(in: result.output) {
                if let diagnostic = message["emitDiagnostic"] as? [String: Any] {
                    let severity = diagnostic["severity"] as? String ?? "warning"
                    let text = diagnostic["message"] as? String ?? ""
                    FileHandle.standardError.write(Data("\(invocation.plugin) \(severity): \(text)\n".utf8))
                    continue
                }

                /// What a command plugin may ask the host to do for it, which
                /// this host does not: a build here is Bazel's, and its
                /// arguments are not the ones SwiftPM would answer with.
                for request in ["buildOperationRequest", "testOperationRequest", "symbolGraphRequest"]
                    where message[request] != nil
                {
                    throw RunnerError(description: """
                    the \(invocation.plugin) plugin asked the host for \(request), which this host does not answer: \
                    build and test the workspace with bazel instead
                    """)
                }
            }

            guard result.succeeded else {
                throw RunnerError(description: errors(result.error))
            }
        }

        private static func run(_ invocation: Invocation, runfiles: String) async throws {
            let files = FileManager.default
            if invocation.resetOutput, files.fileExists(atPath: invocation.output) {
                try files.removeItem(atPath: invocation.output)
            }
            try files.createDirectory(atPath: invocation.output, withIntermediateDirectories: true)

            guard let encoded = Data(base64Encoded: invocation.request) else {
                throw RunnerError(description: "the generated request is not base64")
            }
            let decoded = try JSONSerialization.jsonObject(with: encoded)
            let replaced = replacingRunfiles(in: decoded, with: runfiles)
            let refreshed = try refreshingSources(in: replaced)
            let payload = try JSONSerialization.data(withJSONObject: refreshed)

            var length = UInt64(payload.count).littleEndian
            var input = withUnsafeBytes(of: &length) { Data($0) }
            input.append(payload)

            let executable = URL(fileURLWithPath: runfiles).appendingPathComponent(invocation.executable).path
            let result = try await Commands.runPlugin(executable: executable, input: input)
            let responses = try messages(in: result.output)
            let commands = try handle(responses)

            if !result.succeeded, commands.isEmpty {
                throw RunnerError(description: errors(result.error))
            }

            for command in commands {
                try await Commands.runBuildCommand(command)
            }
        }

        private static func replacingRunfiles(in value: Any, with runfiles: String) -> Any {
            if let string = value as? String {
                return string.replacingOccurrences(of: "$RUNFILES", with: runfiles)
            }
            if let array = value as? [Any] {
                return array.map { replacingRunfiles(in: $0, with: runfiles) }
            }
            if let dictionary = value as? [String: Any] {
                return dictionary.mapValues { replacingRunfiles(in: $0, with: runfiles) }
            }
            return value
        }

        /// Source additions do not require regenerating the workspace. Refresh the
        /// one target whose files a build-tool plugin is allowed to inspect.
        private static func refreshingSources(in value: Any) throws -> Any {
            guard
                var request = value as? [String: Any],
                var body = request["createBuildToolCommands"] as? [String: Any],
                var context = body["context"] as? [String: Any],
                var targets = context["targets"] as? [[String: Any]],
                let targetId = body["targetId"] as? Int,
                targets.indices.contains(targetId),
                var info = targets[targetId]["info"] as? [String: Any],
                let directoryId = targets[targetId]["directoryId"] as? Int,
                let paths = context["paths"] as? [[String: Any]],
                let directory = path(directoryId, in: paths)
            else {
                return value
            }

            let key: String
            if info["swiftSourceModuleInfo"] != nil {
                key = "swiftSourceModuleInfo"
            } else if info["clangSourceModuleInfo"] != nil {
                key = "clangSourceModuleInfo"
            } else {
                return value
            }

            guard var module = info[key] as? [String: Any] else { return value }
            let root = URL(fileURLWithPath: directory, isDirectory: true)
            let prefix = root.path.hasSuffix("/") ? root.path : root.path + "/"
            module["sourceFiles"] = try walk(root).map { file -> [String: Any] in
                let path = file.path
                let name = path.hasPrefix(prefix) ? String(path.dropFirst(prefix.count)) : file.lastPathComponent
                return ["basePathId": directoryId, "name": name, "type": fileType(file)]
            }
            info[key] = module
            targets[targetId]["info"] = info
            context["targets"] = targets
            body["context"] = context
            request["createBuildToolCommands"] = body
            return request
        }

        private static func path(_ id: Int, in paths: [[String: Any]]) -> String? {
            guard paths.indices.contains(id), let subpath = paths[id]["subpath"] as? String else {
                return nil
            }
            guard let base = paths[id]["baseURLId"] as? Int, let root = path(base, in: paths) else {
                return subpath
            }
            return URL(fileURLWithPath: root, isDirectory: true).appendingPathComponent(subpath).path
        }

        private static func walk(_ root: URL) throws -> [URL] {
            var files: [URL] = []
            var visited: Set<String> = []

            func visit(_ directory: URL) throws {
                let resolved = directory.resolvingSymlinksInPath().standardizedFileURL.path
                guard visited.insert(resolved).inserted else { return }

                let children = try FileManager.default.contentsOfDirectory(
                    at: directory,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [])
                    .sorted { $0.path < $1.path }
                for child in children {
                    if try child.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true {
                        try visit(child)
                    } else {
                        files.append(child)
                    }
                }
            }

            try visit(root)
            return files
        }

        private static func fileType(_ file: URL) -> String {
            let headers: Set<String> = ["h", "hh", "hpp", "hxx", "inc"]
            let sources: Set<String> = ["swift", "c", "cc", "cpp", "cxx", "m", "mm", "S", "s"]
            if headers.contains(file.pathExtension) { return "header" }
            if sources.contains(file.pathExtension) { return "source" }
            return "resource"
        }

        private static func messages(in data: Data) throws -> [[String: Any]] {
            var messages: [[String: Any]] = []
            var offset = 0

            while offset + 8 <= data.count {
                var count: UInt64 = 0
                for index in 0 ..< 8 {
                    count |= UInt64(data[offset + index]) << UInt64(index * 8)
                }
                let start = offset + 8
                guard count > 0, count <= UInt64(Int.max), start + Int(count) <= data.count else {
                    throw RunnerError(description: "a plugin response claims \(count) bytes and the stream has fewer")
                }

                let payload = data[start ..< start + Int(count)]
                guard let message = try JSONSerialization.jsonObject(with: payload) as? [String: Any] else {
                    throw RunnerError(description: "a plugin response is not a JSON object")
                }
                messages.append(message)
                offset = start + Int(count)
            }

            return messages
        }

        private static func handle(_ messages: [[String: Any]]) throws -> [[String: Any]] {
            var commands: [[String: Any]] = []

            for message in messages {
                if let diagnostic = message["emitDiagnostic"] as? [String: Any] {
                    let severity = diagnostic["severity"] as? String ?? "warning"
                    let text = diagnostic["message"] as? String ?? ""
                    FileHandle.standardError.write(Data("plugin \(severity): \(text)\n".utf8))
                } else if let build = message["defineBuildCommand"] as? [String: Any],
                          let configuration = build["configuration"] as? [String: Any]
                {
                    commands.append(configuration)
                } else if let prebuild = message["definePrebuildCommand"] as? [String: Any],
                          let configuration = prebuild["configuration"] as? [String: Any]
                {
                    if let directory = prebuild["outputFilesDirectory"] as? String {
                        try FileManager.default.createDirectory(
                            atPath: filePath(directory),
                            withIntermediateDirectories: true)
                    }
                    commands.append(configuration)
                }
            }

            return commands
        }


        static func filePath(_ value: String) -> String {
            guard value.hasPrefix("file://") else { return value }
            return URL(string: value)?.path ?? value
        }

        static func errors(_ output: String) -> String {
            let lines = output.split(separator: "\n").map {
                $0.trimmingCharacters(in: .whitespaces)
            }
            let reasons = lines.filter { $0.lowercased().hasPrefix("error:") }.suffix(3)
            if !reasons.isEmpty { return reasons.joined(separator: " ") }
            return String(output.suffix(400)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private enum Commands {
        struct PluginResult {
            let succeeded: Bool
            let output: Data
            let error: String
        }

        static func runPlugin(executable: String, input: Data) async throws -> PluginResult {
            let result = try await Subprocess.run(
                .path(FilePath(executable)),
                input: .data(input),
                output: .data(limit: Int.max),
                error: .data(limit: Int.max))
            return .init(
                succeeded: result.terminationStatus.isSuccess,
                output: result.standardOutput,
                error: String(data: result.standardError, encoding: .utf8) ?? "")
        }

        static func runBuildCommand(_ command: [String: Any]) async throws {
            guard let executable = command["executable"] as? String else {
                throw RunnerError(description: "a plugin command has no executable")
            }
            let arguments = (command["arguments"] as? [String] ?? []).map(PluginHost.filePath)
            let overrides = command["environment"] as? [String: String] ?? [:]
            let environment = Dictionary<Environment.Key, String?>(uniqueKeysWithValues:
                overrides.map { (.init(stringLiteral: $0.key), $0.value) })
            let directory = (command["workingDirectory"] as? String).map(PluginHost.filePath)
            let result = try await Subprocess.run(
                .path(FilePath(PluginHost.filePath(executable))),
                arguments: Arguments(arguments),
                environment: .inherit.updating(environment),
                workingDirectory: directory.map { FilePath($0) },
                output: .discarded,
                error: .data(limit: Int.max))
            guard result.terminationStatus.isSuccess else {
                let name = command["displayName"] as? String
                    ?? URL(fileURLWithPath: PluginHost.filePath(executable)).lastPathComponent
                let error = String(data: result.standardError, encoding: .utf8) ?? ""
                throw RunnerError(description: "\(name): \(PluginHost.errors(error))")
            }
        }
    }
    """#
}
