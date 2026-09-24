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
        abstract: "Generate Bazel workspaces from Xcode and Swift package inputs.",
        discussion: "Run without a subcommand to generate a workspace.",
        version: version,
        subcommands: [
            GenerateCommand.self,
            DumpCommand.self
        ],
        defaultSubcommand: GenerateCommand.self)
}

// MARK: - GenerateCommand

struct GenerateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Generate a Bazel workspace from an input.",
        discussion: """
        Generated files are written under --output; the input source tree is not \
        modified.
        """)

    @Option(
        name: [.customLong("input", withSingleDash: false)],
        help: "Path to the Xcode or Swift package input.")
    var input: String

    @Option(
        name: [.customLong("output", withSingleDash: false)],
        help: "Directory where the Bazel workspace is written.")
    var output: String

    @Option(name: [.short], help: "Preferred Xcode build configuration.")
    var config = "Release"

    func run() async throws {
        let path = Path.current + input
        let outputPath = Path.current + output
        let kit = try await Kit(
            path,
            config,
            outputPath: outputPath)

        try await kit.run()
    }
}

// MARK: - DumpCommand

struct DumpCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dump",
        abstract: "Inspect a parsed Xcode input.",
        discussion: "Prints the parsed model as JSON unless --print-target is provided.")

    @Option(
        name: [.customLong("input", withSingleDash: false)],
        help: "Path to the Xcode input to inspect.")
    var input: String

    @Option(name: [.short], help: "Preferred Xcode build configuration to resolve.")
    var config: String?

    @Option(
        name: [.customLong("print-target", withSingleDash: false)],
        help: "Print a readable summary for the named target instead of JSON.")
    var printTarget: String?

    func run() async throws {
        let path = Path.current + input
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
