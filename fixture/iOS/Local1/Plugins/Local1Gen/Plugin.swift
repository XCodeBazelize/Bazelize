import Foundation
import PackagePlugin

/// A build tool plugin whose tool writes more than Swift: the sources a target
/// compiles, a header those sources include, and a resource it bundles.
///
/// The package's own executable target is the tool, the way TbCodeGenerater's is.
@main
struct Local1Gen: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        let tool = try context.tool(named: "Local1Tool")
        let directory = context.pluginWorkDirectory

        /// A C-family target compiles what the plugin writes as C; a Swift one
        /// compiles the Swift and bundles the rest.
        let kind = target.name == "LocalTarget3" ? "clang" : "swift"
        let outputs = kind == "clang"
            ? ["LocalTarget3Generated.c", "LocalTarget3Generated.h"]
            : ["Local1Generated.swift", "assets/local1-generated.json"]

        return [
            .buildCommand(
                displayName: "Generate \(kind) files for \(target.name)",
                executable: tool.path,
                arguments: ["--kind", kind, "--output", directory.string],
                outputFiles: outputs.map { directory.appending($0) }),
        ]
    }
}
