import Foundation
import PackagePlugin

@main
struct Mark: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        let directory = context.pluginWorkDirectoryURL.appending(component: "Marked")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let output = directory.appending(component: "Mark.generated.swift")

        return [
            .prebuildCommand(
                displayName: "Mark \(target.name)",
                executable: URL(fileURLWithPath: "/bin/sh"),
                arguments: [
                    "-c",
                    "printf 'public let mark = \"marked %s\"\\n' '\(target.name)' > '\(output.path())'",
                ],
                outputFilesDirectory: directory),
        ]
    }
}
