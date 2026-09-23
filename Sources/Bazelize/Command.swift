//
//  Command.swift
//
//
//  Created by Yume on 2022/4/28.
//

import ArgumentParser
import BazelizeKit
import Foundation
import PathKit
import Xcode

// MARK: - Command

@main
struct Command: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "bazelize",
        abstract: "A cli tool turn your xcode project to bazel.",
        version: version,
        subcommands: [
            GenerateCommand.self,
            PluginsCommand.self,
            XcodeCommand.self,
//            RoadmapCommand.self,
        ],
        defaultSubcommand: GenerateCommand.self)
}

// MARK: - PluginsCommand

/// Runs build tool plugins directly through bazelize.
///
/// Generated workspaces use their Bazel-built host through
/// `bazel run //:plugins`; this command remains the direct form for callers
/// that supply already-built plugin and tool programs.
struct PluginsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "plugins",
        abstract: "Run the build tool plugins of a generated workspace.")

    @Option(name: [.customLong("output", withSingleDash: false)], help: "PATH/TO/OUTPUT")
    var output = "."

    @Option(name: [.customLong("local", withSingleDash: false)], help: "PATH/TO/LOCAL/PACKAGE")
    var locals: [String] = []

    /// `NAME=PATH`, for plugin programs the caller already built.
    @Option(name: [.customLong("plugin", withSingleDash: false)], help: "NAME=PATH/TO/PLUGIN")
    var plugins: [String] = []

    @Option(name: [.customLong("tool", withSingleDash: false)], help: "NAME=PATH/TO/TOOL")
    var tools: [String] = []

    func run() async throws {
        let outputPath = Path.current + output
        let notes = try await SwiftPM.runPlugins(
            output: outputPath,
            locals: locals.map { Path.current + $0 },
            plugins: Self.programs(plugins),
            tools: Self.programs(tools))

        for note in notes {
            print(note)
        }
    }

    private static func programs(_ arguments: [String]) -> [String: Path] {
        arguments.reduce(into: [:]) { programs, argument in
            guard let separator = argument.firstIndex(of: "=") else { return }
            let name = String(argument[..<separator])
            let path = String(argument[argument.index(after: separator)...])
            programs[name] = Path.current + path
        }
    }
}

// MARK: - GenerateCommand

struct GenerateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Generate Bazel files from an Xcode project.")

    @Option(name: [.customLong("project", withSingleDash: false)], help: "PATH/TO/YOUR.xcodeproj")
    var project: String

    @Option(name: [.customLong("output", withSingleDash: false)], help: "PATH/TO/OUTPUT")
    var output: String

    @Option(name: [.short], help: "Debug/Release")
    var config = "Release"

    @Option(name: [.long], help: "plugin list")
    var manifest = ".bazelize.yml"

    @Flag
    var dump = false

    @Flag
    var clear = false

    func run() async throws {
        let path = Path.current + project
        let outputPath = Path.current + output
        let kit = try await Kit(
            path,
            config,
            outputPath: outputPath)

        guard !clear else {
            kit.clear()
            return
        }

        if dump {
            try kit.dump()
        } else {
            try await kit.run(Path(manifest))
        }
    }
}

// MARK: - XcodeCommand

struct XcodeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "xcode",
        abstract: "Dump an Xcode project structure as JSON or print one target summary.")

    @Option(name: [.customLong("project", withSingleDash: false)], help: "PATH/TO/YOUR.xcodeproj")
    var project: String

    @Option(name: [.short], help: "Preferred config name used by project parsing")
    var config: String?

    @Option(
        name: [.customLong("print-target", withSingleDash: false)],
        help: "Print a human-readable summary for a single target")
    var printTarget: String?

    func run() async throws {
        let path = Path.current + project
        let dump = try Xcode.Project.load(path: path, preferConfig: config)

        if let printTarget {
            guard let target = dump.targets.first(where: { $0.name == printTarget }) else {
                throw ValidationError("Target '\(printTarget)' not found.")
            }

            print(Xcode.TargetSummaryFormatter.format(project: dump, target: target))
            return
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

        let data = try encoder.encode(dump)
        guard let json = String(data: data, encoding: .utf8) else {
            throw ValidationError("Failed to encode JSON output.")
        }

        print(json)
    }
}
