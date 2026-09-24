import Foundation
import PackagePlugin

@main
struct GenerateGreeting: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        let output = context.pluginWorkDirectoryURL.appending(component: "Greeting.generated.swift")
        let tool = try context.tool(named: "GreetTool")

        return [
            .buildCommand(
                displayName: "Write the greeting",
                executable: tool.url,
                arguments: [output.path()],
                outputFiles: [output]),
        ]
    }
}
