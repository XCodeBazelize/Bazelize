import ArgumentParser
import Foundation
import RepoEnumCore

@main
struct RepoEnumGeneratorCommand: AsyncParsableCommand {
    @Option(name: .long, help: "YAML config file listing repo enum sources.")
    var config = "RepoSources.yml"

    @Option(name: .long, help: "Directory where generated Repo+*.swift files will be written.")
    var output = "Generated"

    mutating func run() async throws {
        let currentDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
        let configPath = RepoEnumPaths.resolve(config, from: currentDirectory)
        let outputPath = RepoEnumPaths.resolve(output, from: currentDirectory, isDirectory: true)

        let service = RepoEnumGeneratorService()
        try await service.generate(
            configFile: configPath,
            outputDirectory: outputPath)
    }
}
