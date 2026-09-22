import Foundation
import PackagePlugin

@main
struct RecordVersion: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        let output = context.pluginWorkDirectoryURL.appending(component: "Version.generated.swift")
        /// The program the bundle ships, asked for by the name the bundle's
        /// `info.json` files it under.
        let tool = try context.tool(named: "periphery")

        return [
            .buildCommand(
                displayName: "Record what the bundled program answers",
                executable: URL(fileURLWithPath: "/bin/sh"),
                arguments: [
                    "-c",
                    """
                    answer="$('\(tool.url.path())' version 2>&1)"
                    printf 'public let toolVersion = "%s"\\n' "$answer" > '\(output.path())'
                    """,
                ],
                outputFiles: [output]),
        ]
    }
}
