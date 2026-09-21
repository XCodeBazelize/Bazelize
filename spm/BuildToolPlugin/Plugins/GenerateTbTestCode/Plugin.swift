import Foundation
import PackagePlugin

@main
struct GeneratePATForScipioDeploy: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        let generatedSourceDirectoryURL = context.pluginWorkDirectoryURL
        let generatedSourceURL = generatedSourceDirectoryURL
            .appending(component: "TestOptions.generated.swift")
        
        let optionURL = context.package.directoryURL
            .appending(component: "TestOptions.tb")
        
        let tool = try context.tool(named: "TbCodeGenerater")
        
        return [
            .buildCommand(
                displayName: "Generate options",
                executable: tool.url,
                arguments: [
                    "-i", optionURL.path(),
                    "-o", generatedSourceURL.path(),
                    "--name", "TestOptions"
                ],
                outputFiles: [generatedSourceURL]
            ),
        ]
    }
}
