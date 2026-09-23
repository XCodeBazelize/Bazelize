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

    private struct Invocation: Decodable {
        let package: String
        let target: String
        let plugin: String
        let executable: String
        let output: String
        let resetOutput: Bool
        let request: String
    }

    private struct ProcessResult {
        let status: Int32
        let output: Data
        let error: String
    }

    private struct RunnerError: Error, CustomStringConvertible {
        let description: String
    }

    @main
    private enum PluginHost {
        static func main() {
            do {
                try run()
            } catch {
                FileHandle.standardError.write(Data("plugin host: \(error)\n".utf8))
                exit(1)
            }
        }

        private static func run() throws {
            guard CommandLine.arguments.count == 3 else {
                throw RunnerError(description: "expected PLAN RUNFILES")
            }

            let plan = URL(fileURLWithPath: CommandLine.arguments[1])
            let runfiles = CommandLine.arguments[2]
            let invocations = try JSONDecoder().decode([Invocation].self, from: Data(contentsOf: plan))

            for invocation in invocations {
                do {
                    try run(invocation, runfiles: runfiles)
                } catch {
                    let subject = "\(invocation.package)/\(invocation.target)"
                    let reason = "did not run the \(invocation.plugin) plugin: \(error)."
                    print("\(subject) \(reason) Whatever that plugin generates is missing from the target.")
                }
            }
        }

        private static func run(_ invocation: Invocation, runfiles: String) throws {
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
            let result = try process(executable: executable, input: input)
            let responses = try messages(in: result.output)
            let commands = try handle(responses)

            if result.status != 0, commands.isEmpty {
                throw RunnerError(description: errors(result.error))
            }

            for command in commands {
                try execute(command)
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

        private static func execute(_ command: [String: Any]) throws {
            guard let executable = command["executable"] as? String else {
                throw RunnerError(description: "a plugin command has no executable")
            }

            let arguments = (command["arguments"] as? [String] ?? []).map(filePath)
            var environment = ProcessInfo.processInfo.environment
            for (key, value) in command["environment"] as? [String: String] ?? [:] {
                environment[key] = value
            }
            let workingDirectory = (command["workingDirectory"] as? String).map(filePath)
            let result = try process(
                executable: filePath(executable),
                arguments: arguments,
                environment: environment,
                workingDirectory: workingDirectory)

            guard result.status == 0 else {
                let name = command["displayName"] as? String
                    ?? URL(fileURLWithPath: filePath(executable)).lastPathComponent
                throw RunnerError(description: "\(name): \(errors(result.error))")
            }
        }

        private static func process(
            executable: String,
            arguments: [String] = [],
            environment: [String: String]? = nil,
            workingDirectory: String? = nil,
            input: Data? = nil) throws -> ProcessResult
        {
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("bazelize-plugin-host-\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: directory) }

            let inputURL = directory.appendingPathComponent("stdin")
            let outputURL = directory.appendingPathComponent("stdout")
            let errorURL = directory.appendingPathComponent("stderr")
            try (input ?? Data()).write(to: inputURL)
            FileManager.default.createFile(atPath: outputURL.path, contents: nil)
            FileManager.default.createFile(atPath: errorURL.path, contents: nil)

            let inputHandle = try FileHandle(forReadingFrom: inputURL)
            let outputHandle = try FileHandle(forWritingTo: outputURL)
            let errorHandle = try FileHandle(forWritingTo: errorURL)
            defer {
                try? inputHandle.close()
                try? outputHandle.close()
                try? errorHandle.close()
            }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            process.environment = environment
            if let workingDirectory {
                process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory, isDirectory: true)
            }
            process.standardInput = inputHandle
            process.standardOutput = outputHandle
            process.standardError = errorHandle

            try process.run()
            process.waitUntilExit()
            try outputHandle.close()
            try errorHandle.close()

            let output = try Data(contentsOf: outputURL)
            let error = String(data: try Data(contentsOf: errorURL), encoding: .utf8) ?? ""
            return .init(status: process.terminationStatus, output: output, error: error)
        }

        private static func filePath(_ value: String) -> String {
            guard value.hasPrefix("file://") else { return value }
            return URL(string: value)?.path ?? value
        }

        private static func errors(_ output: String) -> String {
            let lines = output.split(separator: "\n").map {
                $0.trimmingCharacters(in: .whitespaces)
            }
            let reasons = lines.filter { $0.lowercased().hasPrefix("error:") }.suffix(3)
            if !reasons.isEmpty { return reasons.joined(separator: " ") }
            return String(output.suffix(400)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    """#
}
