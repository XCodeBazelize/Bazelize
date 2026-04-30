import Foundation
import PackagePlugin

// MARK: - RepoEnumPlugin

@main
struct RepoEnumPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let tool = try context.tool(named: "RepoEnumGenerator")
        let process = Process()
        process.executableURL = tool.url
        process.currentDirectoryURL = context.package.directoryURL
        process.arguments = arguments

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw RepoEnumPluginError.executionFailed(status: process.terminationStatus)
        }
    }
}

// MARK: - RepoEnumPluginError

private enum RepoEnumPluginError: LocalizedError {
    case executionFailed(status: Int32)

    var errorDescription: String? {
        switch self {
        case .executionFailed(let status):
            return "RepoEnumGenerator exited with status \(status)."
        }
    }
}
