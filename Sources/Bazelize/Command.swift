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
            XcodeCommand.self,
//            RoadmapCommand.self,
        ],
        defaultSubcommand: GenerateCommand.self)
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
