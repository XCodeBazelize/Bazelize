import Foundation
import PackagePlugin

@main
struct Stamp: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        let output = context.pluginWorkDirectoryURL.appending(component: "Stamp.generated.swift")
        let tool = try context.tool(named: "StampTool")

        return [
            .buildCommand(
                displayName: "Stamp \(target.name)",
                executable: tool.url,
                arguments: [output.path(), target.name],
                outputFiles: [output]),
        ]
    }
}
