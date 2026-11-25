//
//  Commands+Plugin.swift
//
//  Fetching and building bazelize plugins.
//

@preconcurrency import PathKit
import System
import Util

extension Commands {
    public static func clonePluginRepository(url: String, name: String, in directory: Path) async throws {
        try await pluginStep("git", ["clone", url, name], in: directory)
    }

    public static func checkoutPluginRevision(_ revision: String, in repository: Path) async throws {
        try await pluginStep("git", ["checkout", revision], in: repository)
    }

    public static func buildReleasePlugin(in repository: Path) async throws {
        try await pluginStep("swift", ["build", "-c", "release"], in: repository)
    }

    private static func pluginStep(_ executable: String, _ arguments: [String], in directory: Path) async throws {
        Log.pluginLoader.info("\(directory.string)> \(executable) \(arguments.joined(separator: " "))")
        try await execute(executable, arguments, in: FilePath(directory.string))
    }
}
