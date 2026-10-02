import Foundation
import PackagePlugin

@main
struct GeneratePrebuild: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        let directory = context.pluginWorkDirectoryURL.appending(component: "Prebuild")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let output = directory.appending(component: "Prebuilt.generated.swift")

        return [
            .prebuildCommand(
                displayName: "Write a source before the build",
                executable: URL(fileURLWithPath: "/bin/sh"),
                arguments: [
                    "-c",
                    "printf '%s\\n' 'public let prebuilt = \"written before the build\"' > \(output.path())",
                ],
                outputFilesDirectory: directory),
        ]
    }
}
